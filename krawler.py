#!/usr/bin/env python3

import cloudscraper
from bs4 import BeautifulSoup
from urllib.parse import urlparse, parse_qs
import json
import re
import time
import sys
import os
import random
from stem import Signal
from stem.control import Controller
import threading
from queue import Queue
import requests

SUSPICIOUS_NAMES = ['q', 'search', 'id', 'user', 'email', 'token', 'redirect', 'lang', 'debug']
MAX_THREADS = 10
PROXIES = [
    'socks5h://127.0.0.1:9050',
]

scraper = cloudscraper.create_scraper(
    browser={
        'browser': 'chrome',
        'platform': 'windows',
        'mobile': False
    }
)

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/122 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1"
}

proxy_index = 0
lock = threading.Lock()
completed = 0


def renew_tor_ip():
    with Controller.from_port(port=9051) as controller:
        controller.authenticate()
        controller.signal(Signal.NEWNYM)
        time.sleep(3)


def get_next_proxy():
    global proxy_index
    proxy = PROXIES[proxy_index % len(PROXIES)]
    proxy_index += 1
    return {"http": proxy, "https": proxy}


def analyze_url(url, total):
    global scraper, completed
    try:
        start = time.time()
        response = scraper.get(url, headers=headers, timeout=10, allow_redirects=True, proxies=get_next_proxy())
        load_time = round(time.time() - start, 3)
    except Exception as e:
        print(f"[-] {url} => ERROR: {e}")
        with lock:
            completed += 1
            print(f"[PROGRESS] {completed}/{total} ({round((completed/total)*100)}%)")
        return {"url": url, "error": str(e)}

    status_code = response.status_code
    redirect_to = response.url if response.history else None
    print(f"[+] {url} => Status: {status_code}{' | Redirect: ' + redirect_to if redirect_to else ''}")

    if status_code == 429:
        print("    ↳ [!] Too Many Requests — cambiando IP...")
        renew_tor_ip()
        time.sleep(random.uniform(3, 7))

    if redirect_to in seen_urls:
        print("    ↳ Skipped: already in dataset")
        with lock:
            completed += 1
            print(f"[PROGRESS] {completed}/{total} ({round((completed/total)*100)}%)")
        return None

    soup = BeautifulSoup(response.text, "html.parser")
    forms = soup.find_all("form")
    inputs = soup.find_all("input")
    textareas = soup.find_all("textarea")
    cookies = response.cookies
    headers_resp = response.headers

    input_names = [i.get("name", "").lower() for i in inputs if i.get("name")]
    suspicious_found = [n for n in input_names if any(s in n for s in SUSPICIOUS_NAMES)]

    form_methods = list(set([f.get("method", "get").lower() for f in forms]))
    external_forms = [f.get("action") for f in forms if f.get("action") and urlparse(f.get("action")).netloc not in urlparse(url).netloc]

    query_params = parse_qs(urlparse(url).query)
    suspicious_params = [p for p in query_params if any(s in p for s in SUSPICIOUS_NAMES)]
    suspicious_values = [v for val in query_params.values() for v in val if re.match(r'^[A-Za-z0-9+/=]{16,}$', v)]

    reflected_inputs = [name for name in input_names if name in response.text]

    with lock:
        completed += 1
        print(f"[PROGRESS] {completed}/{total} ({round((completed/total)*100)}%)")

    seen_urls.add(redirect_to or url)

    return {
        "url": url,
        "status_code": status_code,
        "redirect_location": redirect_to,
        "title": soup.title.string.strip() if soup.title else "",
        "response_time": load_time,
        "redirected": bool(response.history),
        "technologies": list(filter(None, [
            headers_resp.get("Server", ""),
            headers_resp.get("X-Powered-By", "")
        ])),
        "forms": len(forms),
        "inputs": len(inputs),
        "textareas": len(textareas),
        "input_types": list(set([i.get("type", "text") for i in inputs])),
        "input_names": input_names,
        "suspicious_names": suspicious_found,
        "form_methods": form_methods,
        "external_actions": external_forms,
        "has_autocomplete_off": any(i.get("autocomplete") == "off" for i in inputs),
        "has_file_input": any(i.get("type") == "file" for i in inputs),
        "has_search_input": any(i.get("type") == "search" for i in inputs),
        "hidden_inputs": sum(1 for i in inputs if i.get("type") == "hidden"),
        "visible_inputs": sum(1 for i in inputs if i.get("type") != "hidden"),
        "reflected_inputs": reflected_inputs,
        "suspicious_query_params": suspicious_params,
        "suspicious_values": suspicious_values,
        "headers": {
            "Content-Security-Policy": headers_resp.get("Content-Security-Policy", ""),
            "X-Frame-Options": headers_resp.get("X-Frame-Options", ""),
            "X-Content-Type-Options": headers_resp.get("X-Content-Type-Options", ""),
            "Strict-Transport-Security": headers_resp.get("Strict-Transport-Security", ""),
            "Referrer-Policy": headers_resp.get("Referrer-Policy", ""),
            "Permissions-Policy": headers_resp.get("Permissions-Policy", ""),
            "Set-Cookie": headers_resp.get("Set-Cookie", "")
        },
        "has_httponly_cookie": any("httponly" in c.output().lower() for c in cookies),
        "has_secure_cookie": any("secure" in c.output().lower() for c in cookies)
    }

def worker(total):
    while not queue.empty():
        url = queue.get()
        result = analyze_url(url, total)
        if result:
            results.append(result)
        time.sleep(random.uniform(1.5, 3))
        queue.task_done()

queue = Queue()
results = []
seen_urls = set()

def main():
    if len(sys.argv) != 2:
        print("Uso: python3 crawl_urls.py <archivo_urls>")
        sys.exit(1)

    input_file = sys.argv[1]

    if not os.path.isfile(input_file):
        print(f"❌ Archivo no encontrado: {input_file}")
        sys.exit(1)

    with open(input_file, "r") as f:
        urls = [line.strip() for line in f if line.strip()]

    for url in urls:
        queue.put(url)

    total = len(urls)
    threads = []
    for _ in range(min(MAX_THREADS, total)):
        t = threading.Thread(target=worker, args=(total,))
        t.start()
        threads.append(t)

    queue.join()

    for t in threads:
        t.join()

    base = os.path.splitext(os.path.basename(input_file))[0]
    output_file = f"report-{base}.json"

    with open(output_file, "w") as f:
        json.dump(results, f, indent=2)

    print(f"\n[✓] Análisis completo. Resultados guardados en: {output_file}")

if __name__ == "__main__":
    main()
