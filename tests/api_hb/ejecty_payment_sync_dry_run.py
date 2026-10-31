import json
import os
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def load_local_env():
    env_path = Path(__file__).parents[2] / ".env"
    if not env_path.is_file():
        return

    for line in env_path.read_text(encoding="utf-8").splitlines():
        if line and not line.startswith("#") and "=" in line:
            name, value = line.split("=", 1)
            os.environ.setdefault(name.strip(), value.strip())


def request_json(url, method="GET", headers=None, payload=None):
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = Request(url, data=data, headers=headers or {}, method=method)
    with urlopen(request, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def main():
    load_local_env()
    base_url = os.getenv("EJECTY_API_BASE_URL", os.getenv("HB_API_BASE_URL", "")).rstrip("/")
    if not base_url or not os.getenv("HB_TOKEN_USERNAME") or not os.getenv("HB_TOKEN_PASSWORD"):
        raise SystemExit("Configure EJECTY_API_BASE_URL, HB_TOKEN_USERNAME e HB_TOKEN_PASSWORD")

    token_url = base_url + "/api/oauth2/v1/token?" + urlencode(
        {
            "grant_type": "password",
            "username": os.environ["HB_TOKEN_USERNAME"],
            "password": os.environ["HB_TOKEN_PASSWORD"],
        }
    )
    token = request_json(token_url, method="POST")["access_token"]
    tenant_id = os.getenv("EJECTY_TENANT_ID", "01,01")
    if "," not in tenant_id:
        raise SystemExit("EJECTY_TENANT_ID deve usar o formato empresa,filial")
    branch = tenant_id.split(",", 1)[1].strip().upper().replace("'", "")
    headers = {
        "Authorization": "Bearer " + token,
        "Content-Type": "application/json",
        "tenantid": tenant_id,
        "x-erp-module": "FIN",
    }
    query = """
        SELECT C5_FILIAL, C5_NUM, C5_PEDECOM, C5_ZZTPPED,
               E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_SALDO,
               E1_ZZPAYID, E1_ZZSTPAY
        FROM SC5010
        INNER JOIN SE1010 ON SE1010.E1_CLIENTE = SC5010.C5_CLIENTE
            AND SE1010.E1_LOJA = SC5010.C5_LOJACLI
            AND SE1010.E1_PEDIDO = SC5010.C5_NUM
        WHERE SC5010.C5_PEDECOM <> ''
            AND SC5010.C5_FILIAL = '""" + branch + """'
            AND (SE1010.E1_ZZSTPAY = '' OR SE1010.E1_ZZSTPAY = 'pending' OR SE1010.E1_ZZSTPAY = 'PENDING')
            AND SE1010.E1_BAIXA = ''
            AND SC5010.D_E_L_E_T_ = ''
            AND SE1010.D_E_L_E_T_ = ''
    """
    response = request_json(
        base_url + "/restqry/consulta",
        method="POST",
        headers=headers,
        payload={"QUERY": query, "ORDEM": "C5_NUM", "PAGINA": 1, "PORPAGINA": 20},
    )
    records = response.get("RETORNOS", [])
    print("Candidatos encontrados: " + str(len(records)))
    for record in records:
        print(
            "|".join(
                str(record.get(field, "")).strip()
                for field in ("C5_FILIAL", "C5_PEDECOM", "E1_PREFIXO", "E1_NUM", "E1_PARCELA", "E1_TIPO", "E1_SALDO")
            )
        )
    print("Simulacao concluida: nenhum pagamento externo ou PUT foi executado.")


if __name__ == "__main__":
    main()