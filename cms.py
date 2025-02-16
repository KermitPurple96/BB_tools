import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import sys
import re
from termcolor import colored
import pyxploitdb
import semver
import base64
import xmltodict
import signal

def sig_handler(sig, frame):
    print(colored("\n\n\t[!] Saliendo...\n", "green"))
    sys.exit(0)
 
signal.signal(signal.SIGINT, sig_handler)

CMS_PATTERNS = {
    "joomla": {
        "keywords": ["joomla", "protostar", "jdoc"],
        "paths": [
            "/administrator/manifests/files/joomla.xml",
            "/plugins/system/cache/cache.xml",
            "/media/system/js/mootools-core.js",
            "/media/system/js/core.js",
        ],
        "version_path": "/administrator/manifests/files/joomla.xml",
        "version_tag": "version"
    },
    "wordpress": {
        "keywords": ["wp-content", "wp-includes", "wordpress"],
        "paths": [
            "/wp-login.php",
            "/wp-admin/",
            "/readme.html"
        ],
        "version_path": "/readme.html",
        "version_regex": r"Version (\d+\.\d+(\.\d+)?)"
    },
    "drupal": {
        "keywords": ["drupal"],
        "paths": [
            "/misc/drupal.js",
            "/core/install.php"
        ],
        "version_path": "/CHANGELOG.txt",
        "version_regex": r"Drupal (\d+\.\d+(\.\d+)?)"
    }
}

def detect_cms(url):

    try:
        headers = {"User-Agent": "Mozilla/5.0"}
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        html = response.text.lower()

        for cms, data in CMS_PATTERNS.items():
            if any(keyword in html for keyword in data["keywords"]):
                return cms

            for path in data["paths"]:
                full_url = url.rstrip("/") + path
                path_response = requests.get(full_url, headers=headers, timeout=5)
                if path_response.status_code == 200:
                    return cms

        return "unknown"
    except requests.exceptions.RequestException:
        return "unknown"

JOOMLA_VERSION_PATHS = {
    "administrator": "/administrator/manifests/files/joomla.xml",
    "README": "/README.txt",
    "cache": "/plugins/system/cache/cache.xml",
    "system": "/media/system/js/core.js",
    "plugins": "/plugins/system/"
}

found_paths = {key: False for key in JOOMLA_VERSION_PATHS.keys()}

def joomla_urls(url):

    parsed_url = urlparse(url)
    base_url = f"{parsed_url.scheme}://{parsed_url.netloc}"
    path = parsed_url.path.strip("/")

    path_parts = path.split("/")
    administrator_found = False
    readme_found = False

    for word in path_parts:
        for key, joomla_path in JOOMLA_VERSION_PATHS.items():
            if found_paths[key]:
                continue
            
            joomla_words = joomla_path.strip("/").split("/")

            if word in joomla_words:
                new_url = f"{base_url}{joomla_path}"

                try:
                    response = requests.get(new_url, headers={"User-Agent": "Mozilla/5.0"}, timeout=5)
                    if response.status_code != 404:
                        print(f"[✔] Joomla versión URL encontrada: {new_url}")
                        found_paths[key] = True
                        if key == "administrator":
                            administrator_found = True
                        if key == "README":
                            readme_found = True

                    else:
                        print(f"[-] No existe: {new_url} (Código 404)")

                except requests.exceptions.RequestException:
                    print(f"[!] Error al probar: {new_url}")

    for key, joomla_path in JOOMLA_VERSION_PATHS.items():
        if not found_paths[key]:
            new_url = f"{base_url}{joomla_path}"
            try:
                response = requests.get(new_url, headers={"User-Agent": "Mozilla/5.0"}, timeout=5)
                if response.status_code != 404:
                    print(f"[✔] Joomla versión URL encontrada: {new_url}")
                    found_paths[key] = True
                    if key == "administrator":
                        administrator_found = True
                    if key == "README":
                        readme_found = True
            except requests.exceptions.RequestException:
                print(f"[!] Error al probar: {new_url}")

    if administrator_found:
        admin_url = f"{base_url}/administrator/manifests/files/joomla.xml"
        try:
            response = requests.get(admin_url, headers={"User-Agent": "Mozilla/5.0"}, timeout=5)
            if response.status_code != 404:
                found_paths["administrator"] = True 

                soup = BeautifulSoup(response.text, "xml")
                version_tag = soup.find("version")
                if version_tag:
                    joomla_version = version_tag.text.strip()
                    print(f"[✔] Joomla versión detectada: {joomla_version} en {admin_url}")
                else:
                    print(f"[!] No se pudo extraer la versión desde {admin_url}")

        except requests.exceptions.RequestException:
            print(f"[!] Error al probar: {admin_url}")

    if readme_found:
        readme_url = f"{base_url}/README.txt"
        try:
            response = requests.get(readme_url, headers={"User-Agent": "Mozilla/5.0"}, timeout=5)
            if response.status_code != 404:
                found_paths["README"] = True 

                match = re.search(r"Joomla!\s*(\d+\.\d+)", response.text, re.IGNORECASE)
                if match:
                    joomla_version = match.group(1)
                    print(f"[✔] Joomla versión detectada: {joomla_version} en {readme_url}")
                else:
                    print(f"[!] No se pudo extraer la versión desde {readme_url}")

        except requests.exceptions.RequestException:
            print(f"[!] Error al probar: {readme_url}")
    return

def fuzz_joomla_components(base_url, wordlist_file):
    try:
        with open(wordlist_file, 'r') as f:
            components = [line.strip() for line in f]
        
        for component in components:
            url = f"{base_url}/index.php?option={component}"
            response = requests.get(url)
            if response.status_code != 404:
                print(f"{url} -> {response.status_code}")
    except Exception as e:
        print(f"Error: {e}")

def is_version_lower(v1, v2):
    try:
        return semver.compare(v1, v2) < 0
    except ValueError:
        return False

def load_payload(method_name):
    try:
        with open("payload_template.xml", "r") as file:
            xml_payload = file.read()
            return xml_payload.replace("{methodName}", method_name)
    except FileNotFoundError:
        print(colored("[-] Archivo 'payload_template.xml' no encontrado.", "red"))
        sys.exit(1)

def parse_fault_response(response_text):
    try:
        parsed_response = xmltodict.parse(response_text)
        fault = parsed_response.get('methodResponse', {}).get('fault', {}).get('value', {}).get('struct', {})
        if fault:
            fault_code = next((int(member['value']['int']) for member in fault['member'] if member['name'] == 'faultCode'), None)
            fault_string = next((member['value']['string'] for member in fault['member'] if member['name'] == 'faultString'), None)
            return fault_code, fault_string
    except Exception as e:
        print(colored(f"[-] Error al parsear la respuesta de fallo: {e}", "red"))
    return None, None

def exploit_xmlrpc(xmlrpc_url):

    list_methods_payload = load_payload("system.listMethods")
    headers = {
        "Content-Type": "application/xml",
    }

    try:
        print(colored(f"[+] Enviando solicitud a {xmlrpc_url} para listar métodos...", "blue"))
        response = requests.post(xmlrpc_url, headers=headers, data=list_methods_payload, timeout=10)

        if response.status_code == 200:
            print(colored(f"[+] Métodos disponibles en {xmlrpc_url}:", "green"))

            try:
                parsed_response = xmltodict.parse(response.text)
                methods = parsed_response['methodResponse']['params']['param']['value']['array']['data']['value']
                method_list = [method['string'] for method in methods]

                with open("methods_available.txt", "w") as file:
                    for method in method_list:
                        method_payload = load_payload(method)

                        try:
                            method_response = requests.post(
                                xmlrpc_url, headers=headers, data=method_payload, timeout=10
                            )

                            fault_code, fault_string = parse_fault_response(method_response.text)
                            if fault_code == 403 or (fault_string and "Insufficient arguments" in fault_string):
                                print(colored(f"[-] {method} responded with 403 status or 'Insufficient arguments'", "red"))
                                continue

                            if method_response.status_code == 200:
                                print(colored(f"[+] Respuesta válida para {method}:", "green"))
                                file.write(method + "\n")
                            else:
                                print(colored(f"[-] Método {method} no devolvió una respuesta significativa.", "red"))

                        except requests.RequestException as e:
                            print(colored(f"[-] Error al probar el método {method}: {e}", "red"))
                print(colored(f"[+] Métodos guardados en 'methods_available.txt'", "green"))
            except Exception as parse_error:
                print(colored(f"[-] Error al parsear el XML: {parse_error}", "red"))
                print(response.text)

        else:
            print(colored(f"[-] Solicitud fallida a {xmlrpc_url} con código de estado {response.status_code}", "red"))

    except requests.RequestException as e:
        print(colored(f"[-] Error al interactuar con {xmlrpc_url}: {e}", "red"))


def wordpress_scan(url, themes=set(), plugins=set(), version=None):
    """
    Detecta plugins, temas y funcionalidades relacionadas con WordPress a partir de URLs.
    Si la URL corresponde a xmlrpc.php, se ejecuta exploit_xmlrpc().
    """
    try:
        if url.endswith("xmlrpc.php"):
            print(colored(f"[+] Detectado xmlrpc.php en {url}", "green"))
            exploit_xmlrpc(url)
            return version

        response = requests.head(url, timeout=10)
        if response.status_code != 200:
            print(colored(f"[-] URL no válida o inaccesible: {url} (HTTP {response.status_code})", "red"))
            return version

        if "/wp-content/themes/" in url:
            theme = url.split("/wp-content/themes/")[1].split("/")[0]
            version = re.search(r'[\?&]ver=([\d\.]+)', url)
            version = version.group(1) if version else 'Desconocida'
            themes.add(f"{theme} (Versión: {version})")

        elif "/wp-content/plugins/" in url:
            plugin = url.split("/wp-content/plugins/")[1].split("/")[0]
            version = re.search(r'[\?&]ver=([\d\.]+)', url)
            version = version.group(1) if version else 'Desconocida'
            plugins.add(f"{plugin} (Versión: {version})")

        if not version and "wp-" in url:
            version = "Desconocida"

    except requests.RequestException as e:
        print(colored(f"[-] Error al procesar {url}: {e}", "red"))

    return version

def search_plugins_and_themes(plugins, themes, version):

    for plugin in plugins:
        name_version = plugin.split(" (Versión: ")
        plugin_name = name_version[0]
        plugin_version = name_version[1][:-1] if len(name_version) > 1 else 'Desconocida'
        print(colored(f"\nBuscando vulnerabilidades para el plugin {plugin_name} (Versión: {plugin_version})", "yellow"))
        results = pyxploitdb.searchEDB(f"{plugin_name}", platform="all", _print=False, nb_results=3)
        
        if isinstance(results, list):
            if results:
                for result in results:
                    exploit_id, description, exploit_type, platform, date_published, verified, port, tag_if_any, author, link = result
                    vuln_version = description.split(" ")[-1]
                    if is_version_lower(plugin_version, vuln_version):
                        print(colored(f"  {description} \n {link}", "blue"))
                    else:
                        print(colored(f"  {description} \n {link}", "red"))
            else:
                print(colored("  No se encontraron vulnerabilidades para este plugin.", "yellow"))
        else:
            print(colored("  Error al obtener resultados de la búsqueda.", "red"))

    for theme in themes:
        name_version = theme.split(" (Versión: ")
        theme_name = name_version[0]
        theme_version = name_version[1][:-1] if len(name_version) > 1 else 'Desconocida'
        print(colored(f"\nBuscando vulnerabilidades para el theme {theme_name} (Versión: {theme_version})", "yellow"))
        
        results = pyxploitdb.searchEDB(f"{theme_name}", platform="all", _print=False, nb_results=3)
        
        if isinstance(results, list):
            if results:
                for result in results:
                    exploit_id, description, exploit_type, platform, date_published, verified, port, tag_if_any, author, link = result
                    vuln_version = description.split(" ")[-1]
                    if is_version_lower(theme_version, vuln_version):
                        print(colored(f"  {description} \n {link}", "blue"))
                    else:
                        print(colored(f"  {description} \n {link}", "red"))
            else:
                print(colored("  No se encontraron vulnerabilidades para este theme.", "yellow"))
        else:
            print(colored("  Error al obtener resultados de la búsqueda.", "red"))

    if version:
        print(colored(f"\nBuscando vulnerabilidades para WordPress (Versión: {version})", "yellow"))
        
        search_query = f"WordPress {version}"
        wp_results = pyxploitdb.searchEDB(search_query, platform="webapps", _print=False, nb_results=3)
        
        if isinstance(wp_results, list):
            if wp_results:
                for wp_result in wp_results:
                    exploit_id, description, exploit_type, platform, date_published, verified, port, tag_if_any, author, link = wp_result
                    vuln_version = description.split(" ")[-1]
                    if is_version_lower(version, vuln_version):
                        print(colored(f"  {description} \n {link}", "blue"))
                    else:
                        print(colored(f"  {description} \n {link}", "red"))
            else:
                print(colored("  No se encontraron vulnerabilidades para esta versión de WordPress.", "yellow"))
        else:
            print(colored("  Error al obtener resultados de la búsqueda.", "red"))

if __name__ == "__main__":

    if len(sys.argv) < 2:
        print("Uso: python wordpress_scan.py <archivo_de_urls>")
        sys.exit(1)

    file_path = sys.argv[1]

    with open(file_path, "r") as file:
        urls = file.readlines()

    all_discovered_paths = set()
    detected_themes = set()
    detected_plugins = set()
    cms_detected = set()
    version = None
    cms=""

    for target_url in urls:
        cms = detect_cms(target_url)

    if cms == "wordpress":
        print(colored(f"\n[+] WordPress detectado (Versión: {version})", "green"))
        for target_url in urls:
            target_url = target_url.strip()
            version = wordpress_scan(target_url, detected_themes, detected_plugins, version)

        if detected_themes:
            print("\nThemes detectados:")
            for theme in sorted(detected_themes):
                print(theme)

        if detected_plugins:
            print("\nPlugins detectados:")
            for plugin in sorted(detected_plugins):
                print(plugin)

        search_plugins_and_themes(detected_plugins, detected_themes, version)
    elif cms == "joomla":
        print(colored(f"\n[+] Joomla detectado", "green"))
        for target_url in urls:
            joomla_urls(target_url)
        base_url = next(iter(urls)).strip().strip("\n\r")
        fuzz_joomla_components(base_url, "joomla_components.txt")

    else:
        print(colored(f"\n[+] WordPress detectado (Versión: {version})", "green"))

  
