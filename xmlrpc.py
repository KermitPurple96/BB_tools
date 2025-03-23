import requests
from termcolor import colored
import xmltodict

def exploit_xmlrpc_anonymously(xmlrpc_url):
    """
    Realiza una solicitud a xmlrpc.php para listar los métodos disponibles y los parsea con xmltodict.
    """
    # Cuerpo de la solicitud (payload XML)
    xml_payload = """<?xml version="1.0"?>
<methodCall>
<methodName>system.listMethods</methodName>
<params></params>
</methodCall>"""

    # Encabezados
    headers = {
        "Content-Type": "application/xml",  # Aseguramos que sea igual al curl
    }

    try:
        print(colored(f"[+] Enviando solicitud a {xmlrpc_url}...", "blue"))
        
        # Realizar la solicitud POST
        response = requests.post(xmlrpc_url, headers=headers, data=xml_payload, timeout=10)

        # Verificar el código de estado
        if response.status_code == 200:
            print(colored(f"[+] Métodos disponibles en {xmlrpc_url}:", "green"))

            # Parsear el XML con xmltodict
            try:
                parsed_response = xmltodict.parse(response.text)
                methods = parsed_response['methodResponse']['params']['param']['value']['array']['data']['value']
                for method in methods:
                    print(f" - {method['string']}")
            except Exception as parse_error:
                print(colored(f"[-] Error al parsear el XML: {parse_error}", "red"))
                print(response.text)  # Imprime la respuesta cruda si hay error al parsear

        else:
            print(colored(f"[-] Solicitud fallida a {xmlrpc_url} con código de estado {response.status_code}", "red"))

    except requests.RequestException as e:
        print(colored(f"[-] Error al interactuar con {xmlrpc_url}: {e}", "red"))


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Uso: python exploit_xmlrpc.py <url-de-xmlrpc.php>")
        sys.exit(1)

    xmlrpc_url = sys.argv[1]
    exploit_xmlrpc_anonymously(xmlrpc_url)
