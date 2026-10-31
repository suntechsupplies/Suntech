import base64
import json
import os
import secrets
import unittest
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def load_local_env():
    env_path = os.path.join(os.path.dirname(__file__), "..", "..", ".env")
    if not os.path.isfile(env_path):
        return

    with open(env_path, encoding="utf-8") as env_file:
        for line in env_file:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            name, value = line.split("=", 1)
            os.environ.setdefault(name.strip(), value.strip())


load_local_env()


def build_test_cpf():
    digits = [int(digit) for digit in f"{secrets.randbelow(1_000_000_000):09d}"]
    first_digit = sum(value * weight for value, weight in zip(digits, range(10, 1, -1)))
    first_digit = (first_digit * 10 % 11) % 10
    digits.append(first_digit)
    second_digit = sum(value * weight for value, weight in zip(digits, range(11, 1, -1)))
    second_digit = (second_digit * 10 % 11) % 10
    digits.append(second_digit)
    return "".join(str(digit) for digit in digits)


class ApiResponse:
    def __init__(self, status, body):
        self.status = status
        self.body = body

    def json(self):
        return json.loads(self.body.decode("utf-8"))


def get_oauth_token():
    username = os.environ["HB_TOKEN_USERNAME"]
    password = os.environ["HB_TOKEN_PASSWORD"]
    credentials = base64.b64encode((username + ":" + password).encode("utf-8")).decode("ascii")
    base_url = os.environ["HB_API_BASE_URL"].rstrip("/")
    url = os.getenv("HB_TOKEN_URL", base_url + "/api/oauth2/v1/token")
    separator = "&" if "?" in url else "?"
    query = urlencode({"grant_type": "password", "username": username, "password": password})
    request = Request(
        url + separator + query,
        headers={"Authorization": "Basic " + credentials, "Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urlopen(request, timeout=30) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except HTTPError as error:
        message = error.read().decode("utf-8", "replace")
        raise AssertionError("OAuth retornou HTTP " + str(error.code) + ": " + message) from error
    except URLError as error:
        raise AssertionError("Nao foi possivel acessar o endpoint OAuth: " + str(error.reason)) from error

    token = payload.get("access_token", "")
    if not token:
        raise AssertionError("A resposta OAuth nao contem access_token")
    return token


class ApiClient:
    def __init__(self, base_url=None):
        self.base_url = (base_url or os.environ["HB_API_BASE_URL"]).rstrip("/")
        token = os.getenv("HB_API_TOKEN", "").strip()
        if not token:
            token = get_oauth_token()
        if not token.lower().startswith("bearer "):
            token = "Bearer " + token
        self.headers = {
            "Accept": "application/json",
            "Authorization": token,
            "X-Company": os.getenv("HB_API_COMPANY", "01"),
            "X-Branch": os.getenv("HB_API_BRANCH", "01"),
        }

    def request(self, method, path, payload=None, query=None, extra_headers=None):
        url = self.base_url + path
        if query:
            url += "?" + urlencode(query)

        headers = self.headers.copy()
        if extra_headers:
            headers.update(extra_headers)
        data = None
        if payload is not None:
            headers["Content-Type"] = "application/json"
            data = json.dumps(payload).encode("utf-8")

        request = Request(url, data=data, headers=headers, method=method)
        try:
            with urlopen(request, timeout=30) as response:
                return ApiResponse(response.status, response.read())
        except HTTPError as error:
            return ApiResponse(error.code, error.read())
        except URLError as error:
            raise AssertionError("Nao foi possivel acessar " + url + ": " + str(error.reason)) from error


class ApiHbContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        missing = []
        if not os.getenv("HB_API_BASE_URL"):
            missing.append("HB_API_BASE_URL")
        has_token = bool(os.getenv("HB_API_TOKEN"))
        has_credentials = bool(os.getenv("HB_TOKEN_USERNAME")) and bool(os.getenv("HB_TOKEN_PASSWORD"))
        if not has_token and not has_credentials:
            missing.append("HB_API_TOKEN ou HB_TOKEN_USERNAME/HB_TOKEN_PASSWORD")
        if missing:
            raise unittest.SkipTest("Variaveis ausentes: " + ", ".join(missing))
        cls.api = ApiClient()

    def assert_json_object(self, response, expected_status):
        self.assertEqual(response.status, expected_status, response.body.decode("utf-8", "replace"))
        payload = response.json()
        self.assertIsInstance(payload, dict)
        return payload

    def test_customers_get_list(self):
        payload = self.assert_json_object(self.api.request("GET", "/customers", query={"page": 1, "pageSize": 1}), 200)
        self.assertIn("success", payload)

    def test_customers_post_invalid_payload(self):
        payload = self.assert_json_object(self.api.request("POST", "/customers", payload={}), 400)
        self.assertFalse(payload["success"])

    def test_customers_sanitizes_text_fields(self):
        customer = self.create_rotating_customer(
            {
                "name": "AUTOTEST O'NEIL \"CLIENTE\" \\ TESTE",
                "shortName": "N'OME \"RED\" \\ TESTE",
                "address": "RUA D'AVILA \"A\" \\ BLOCO\t1\n, 10",
                "contact": "JO'ANA \"CONTATO\" \\ TESTE\t",
                "observation": "Obs d'cliente \"teste\" \\ linha\nfinal",
            }
        )
        code = customer["code"] + customer["store"]
        response = self.assert_json_object(self.api.request("GET", "/customers", query={"code": code}), 200)

        for field in ("name", "shortName", "address", "contact", "observation"):
            value = response["data"][field]
            self.assertFalse(any(char in value for char in "'\"\\\t\r\n"), field + " nao foi sanitizado: " + value)
        self.assertIn("ONEIL", response["data"]["name"])
        self.assertIn("DAVILA", response["data"]["address"])
        self.assertIn("JOANA", response["data"]["contact"])

    def create_rotating_customer(self, overrides=None):
        if os.getenv("HB_ENABLE_CREATE_TESTS", "").lower() != "true":
            self.skipTest("Defina HB_ENABLE_CREATE_TESTS=true para criar um cliente ficticio")

        tax_id = build_test_cpf()
        customer_data = {
            "taxId": tax_id,
            "name": "AUTOTEST API HB " + tax_id,
            "shortName": "AUTOTEST " + tax_id,
            "personType": "F",
            "customerType": "F",
            "stateRegistration": "ISENTO",
            "address": "RUA TESTE AUTOMATIZADO, 1",
            "neighborhood": "CENTRO",
            "city": "ITUPEVA",
            "state": "SP",
            "zipCode": "13295240",
            "cityCode": "24006",
            "areaCode": "11",
            "phone": "999999999",
            "email": "autotest." + tax_id + "@example.test",
            "country": "105",
            "countryCode": "01058",
            "paymentCondition": "030",
            "salespersonCode": "R00052",
            "carrierCode": "T00007",
            "taxGroup": "C03",
            "salesGroup": "000009",
            "icmsContributor": "2",
        }
        if overrides:
            customer_data.update(overrides)

        response = self.assert_json_object(
            self.api.request(
                "POST",
                "/customers",
                payload=customer_data,
            ),
            201,
        )
        self.assertTrue(response["success"])
        self.assertEqual(response["data"]["taxId"], tax_id)
        return response["data"]

    def test_customers_create_rotating_test_customer(self):
        self.create_rotating_customer()

    def test_customers_get_by_code(self):
        customer = self.create_rotating_customer()
        code = customer["code"] + customer["store"]
        response = self.assert_json_object(self.api.request("GET", "/customers", query={"code": code}), 200)
        self.assertTrue(response["success"])
        self.assertEqual(response["data"]["code"], customer["code"])
        self.assertEqual(response["data"]["store"], customer["store"])

    def test_customers_get_by_tax_id(self):
        customer = self.create_rotating_customer()
        response = self.assert_json_object(self.api.request("GET", "/customers", query={"taxId": customer["taxId"]}), 200)
        self.assertTrue(response["success"])
        self.assertEqual(response["data"]["taxId"], customer["taxId"])

    def test_customers_get_missing_code(self):
        response = self.assert_json_object(self.api.request("GET", "/customers", query={"code": "ZZ999901"}), 404)
        self.assertFalse(response["success"])

    def test_customers_get_missing_tax_id(self):
        response = self.assert_json_object(self.api.request("GET", "/customers", query={"taxId": build_test_cpf()}), 404)
        self.assertFalse(response["success"])

    def test_customers_put_invalid_payload(self):
        response = self.assert_json_object(self.api.request("PUT", "/customers", payload={}), 400)
        self.assertFalse(response["success"])

    def test_customers_update_rotating_customer(self):
        customer = self.create_rotating_customer()
        new_short_name = "ATUALIZADO " + customer["taxId"]
        response = self.assert_json_object(
            self.api.request(
                "PUT",
                "/customers",
                payload={"code": customer["code"], "store": customer["store"], "shortName": new_short_name},
            ),
            200,
        )
        self.assertTrue(response["success"])

        code = customer["code"] + customer["store"]
        updated = self.assert_json_object(self.api.request("GET", "/customers", query={"code": code}), 200)
        self.assertEqual(updated["data"]["shortName"], new_short_name)

    def test_orders_get_list(self):
        payload = self.assert_json_object(self.api.request("GET", "/orders", query={"page": 1, "pageSize": 1}), 200)
        self.assertIn("success", payload)

    def test_orders_get_missing_order(self):
        payload = self.assert_json_object(self.api.request("GET", "/orders", query={"orderNumber": "ZZ9999"}), 404)
        self.assertFalse(payload["success"])

    def test_orders_post_invalid_payload(self):
        payload = self.assert_json_object(self.api.request("POST", "/orders", payload={}), 400)
        self.assertFalse(payload["success"])

    def test_orders_put_invalid_payload(self):
        payload = self.assert_json_object(self.api.request("PUT", "/orders", payload={}), 400)
        self.assertFalse(payload["success"])

    def test_orders_marketplace_enqueues_replenishment(self):
        if os.getenv("HB_ENABLE_ZTR_ENQUEUE_TESTS", "").lower() != "true":
            self.skipTest("Defina HB_ENABLE_ZTR_ENQUEUE_TESTS=true em homologacao para criar pedido e fila ZTR")

        external_id = "ZT" + secrets.token_hex(4).upper()
        marketplace_id = "MKP" + secrets.token_hex(5).upper()
        response = self.assert_json_object(
            self.api.request(
                "POST",
                "/orders",
                payload={
                    "branch": "03",
                    "customerCode": "C30156",
                    "customerStore": "03",
                    "paymentCondition": "194",
                    "priceTable": "MKP",
                    "salespersonCode": "R00105",
                    "carrierCode": "T00007",
                    "orderType": "N",
                    "freightType": "C",
                    "currency": 1,
                    "externalId": external_id,
                    "ecommerceOrder": marketplace_id,
                    "orderSource": "B2C",
                    "orderSubtype": "HB",
                    "financialStatus": "7",
                    "commercialStatus": "1",
                    "isReleased": "S",
                    "items": [
                        {
                            "itemNumber": "01",
                            "productCode": "10105560149001",
                            "quantity": 1,
                            "unitPrice": 489.90,
                            "tesCode": "6C5",
                        }
                    ],
                },
            ),
            201,
        )
        order_number = response["data"]["orderNumber"]
        sql = (
            "SELECT TOP 1 ZTR_FILORI, ZTR_PEDORI, ZTR_PEDEXT, ZTR_APIID, "
            "ZTR_FDEST, ZTR_STATUS, ZTR_LIBOK "
            "FROM ZTR010 WHERE D_E_L_E_T_ = ' ' AND ZTR_FILORI = '03' "
            "AND ZTR_PEDORI = '" + order_number + "'"
        )
        queued = self.assert_json_object(
            self.api.request(
                "POST",
                "/restqry/consulta",
                payload={"QUERY": sql, "ORDEM": "ZTR_PEDORI", "PAGINA": 1, "PORPAGINA": 1},
            ),
            201,
        )["RETORNOS"]

        self.assertEqual(len(queued), 1)
        self.assertEqual(queued[0]["ZTR_FILORI"].strip(), "03")
        self.assertEqual(queued[0]["ZTR_PEDEXT"].strip(), marketplace_id)
        self.assertEqual(queued[0]["ZTR_APIID"].strip(), external_id)
        self.assertEqual(queued[0]["ZTR_FDEST"].strip(), "02")
        self.assertEqual(queued[0]["ZTR_STATUS"].strip(), "AG_LIB")
        self.assertEqual(queued[0]["ZTR_LIBOK"].strip(), "N")

        release_sql = (
            "SELECT C5.C5_LIBEROK, C5.C5_ZZSITFI, C6.C6_ITEM, C6.C6_PRODUTO, C6.C6_BLQ, "
            "C6.C6_QTDVEN - C6.C6_QTDENT AS PENDENTE, "
            "(SELECT COALESCE(SUM(C9.C9_QTDLIB), 0) FROM SC9010 C9 "
            "WHERE C9.D_E_L_E_T_ = ' ' AND C9.C9_FILIAL = C6.C6_FILIAL "
            "AND C9.C9_PEDIDO = C6.C6_NUM AND C9.C9_ITEM = C6.C6_ITEM "
            "AND C9.C9_PRODUTO = C6.C6_PRODUTO AND C9.C9_BLCRED = ' ' "
            "AND C9.C9_BLEST IN (' ', '02') AND C9.C9_NFISCAL = ' ') AS LIBERADO "
            "FROM SC5010 C5 JOIN SC6010 C6 ON C6.C6_FILIAL = C5.C5_FILIAL "
            "AND C6.C6_NUM = C5.C5_NUM AND C6.D_E_L_E_T_ = ' ' "
            "WHERE C5.D_E_L_E_T_ = ' ' AND C5.C5_FILIAL = '03' "
            "AND C5.C5_NUM = '" + order_number + "'"
        )
        released_items = self.assert_json_object(
            self.api.request(
                "POST",
                "/restqry/consulta",
                payload={"QUERY": release_sql, "ORDEM": "C6_ITEM", "PAGINA": 1, "PORPAGINA": 100},
            ),
            201,
        )["RETORNOS"]
        self.assertEqual(len(released_items), 1)
        for item in released_items:
            self.assertEqual(item["C6_PRODUTO"].strip(), "10105560149001")
            self.assertEqual(item["C5_ZZSITFI"].strip(), "7")
            self.assertEqual(item["C5_LIBEROK"].strip(), "S")
            self.assertEqual(item["C6_BLQ"].strip(), "")
            self.assertGreater(item["PENDENTE"], 0)
            self.assertGreaterEqual(item["LIBERADO"], item["PENDENTE"])

    def create_rotating_order(self):
        if os.getenv("HB_ENABLE_ORDER_TESTS", "").lower() != "true":
            self.skipTest("Defina HB_ENABLE_ORDER_TESTS=true para criar um pedido ficticio")

        external_id = "AT" + secrets.token_hex(4).upper()
        response = self.assert_json_object(
            self.api.request(
                "POST",
                "/orders",
                payload={
                    "customerCode": "C15568",
                    "customerStore": "01",
                    "paymentCondition": "042",
                    "priceTable": "TTR",
                    "salespersonCode": "R00069",
                    "carrierCode": "T00007",
                    "orderType": "N",
                    "freightType": "C",
                    "currency": 1,
                    "externalId": external_id,
                    "orderSource": "API",
                    "items": [
                        {
                            "itemNumber": "01",
                            "productCode": "10105710977010",
                            "quantity": 1,
                            "unitPrice": 45,
                            "tesCode": "7Y0",
                        }
                    ],
                },
            ),
            201,
        )
        self.assertTrue(response["success"])
        self.assertEqual(response["data"]["externalId"], external_id)
        return response["data"]

    def test_orders_create_rotating_order(self):
        self.create_rotating_order()

    def test_orders_create_batch(self):
        if os.getenv("HB_ENABLE_ORDER_TESTS", "").lower() != "true":
            self.skipTest("Defina HB_ENABLE_ORDER_TESTS=true para criar um pedido ficticio")

        external_id = "AB" + secrets.token_hex(4).upper()
        order = {
            "customerCode": "C15568",
            "customerStore": "01",
            "paymentCondition": "042",
            "priceTable": "TTR",
            "salespersonCode": "R00069",
            "carrierCode": "T00007",
            "orderType": "N",
            "freightType": "C",
            "currency": 1,
            "externalId": external_id,
            "orderSource": "API",
            "items": [{"itemNumber": "01", "productCode": "10105710977010", "quantity": 1, "unitPrice": 45, "tesCode": "7Y0"}],
        }
        response = self.assert_json_object(self.api.request("POST", "/orders", payload={"orders": [order]}), 201)
        self.assertTrue(response["success"])
        result = response["results"][0]
        self.assertTrue(result["success"])
        self.assertEqual(result["externalId"], external_id)

        deleted = self.assert_json_object(self.api.request("DELETE", "/orders", query={"externalId": external_id}), 200)
        self.assertTrue(deleted["success"])

    def test_orders_create_and_verify_each_branch(self):
        if os.getenv("HB_ENABLE_ORDER_TESTS", "").lower() != "true":
            self.skipTest("Defina HB_ENABLE_ORDER_TESTS=true para criar um pedido ficticio")

        branch_data = {
            "01": {"customerCode": "R00117", "customerStore": "01", "paymentCondition": "042", "priceTable": "TSU", "salespersonCode": "R00052", "carrierCode": "T00005", "productCode": "0003.1302", "tesCode": "6V0", "unitPrice": 10.00},
            "02": {"customerCode": "C15545", "customerStore": "01", "paymentCondition": "033", "priceTable": "TSU", "salespersonCode": "R00071", "carrierCode": "T00007", "productCode": "0003.1302", "tesCode": "5B0", "unitPrice": 10.00},
            "03": {"customerCode": "C30156", "customerStore": "03", "paymentCondition": "194", "priceTable": "MKP", "salespersonCode": "R00105", "carrierCode": "T00007", "productCode": "0003.1302", "tesCode": "6C5", "unitPrice": 10.00},
        }
        created = []
        try:
            for branch, data in branch_data.items():
                external_id = "F" + branch + secrets.token_hex(3).upper()
                payload = {
                    "branch": branch,
                    "customerCode": data["customerCode"],
                    "customerStore": data["customerStore"],
                    "paymentCondition": data["paymentCondition"],
                    "priceTable": data["priceTable"],
                    "salespersonCode": data["salespersonCode"],
                    "carrierCode": data["carrierCode"],
                    "orderType": "N",
                    "freightType": "C",
                    "currency": 1,
                    "externalId": external_id,
                    "orderSource": "API",
                    "items": [{"itemNumber": "01", "productCode": data["productCode"], "quantity": 1, "unitPrice": data["unitPrice"], "tesCode": data["tesCode"]}],
                }
                response = self.assert_json_object(self.api.request("POST", "/orders", payload=payload), 201)
                self.assertTrue(response["success"])
                self.assertEqual(response["data"]["branch"], branch)
                created.append((branch, external_id))

                found = self.assert_json_object(self.api.request("GET", "/orders", query={"externalId": external_id}), 200)
                self.assertEqual(found["data"]["branch"], branch)
                self.assertEqual(found["data"]["externalId"], external_id)
        finally:
            for branch, external_id in created:
                response = self.api.request("DELETE", "/orders", payload={"branch": branch, "externalId": external_id})
                self.assertEqual(response.status, 200, response.body.decode("utf-8", "replace"))

    def test_orders_get_by_number_and_external_id(self):
        order = self.create_rotating_order()
        by_number = self.assert_json_object(
            self.api.request("GET", "/orders", query={"orderNumber": order["orderNumber"]}), 200
        )
        self.assertEqual(by_number["data"]["orderNumber"], order["orderNumber"])

        by_external_id = self.assert_json_object(
            self.api.request("GET", "/orders", query={"externalId": order["externalId"]}), 200
        )
        self.assertEqual(by_external_id["data"]["externalId"], order["externalId"])

    def test_orders_update_rotating_order(self):
        order = self.create_rotating_order()
        response = self.assert_json_object(
            self.api.request(
                "PUT",
                "/orders",
                payload={
                    "externalId": order["externalId"],
                    "observation": "ATUALIZADO API HB",
                    "items": [{"itemNumber": "01", "productCode": "10105710977010", "quantity": 1, "unitPrice": 45, "tesCode": "7Y0"}],
                },
            ),
            200,
        )
        self.assertTrue(response["success"])

    def test_orders_delete_rotating_order(self):
        order = self.create_rotating_order()
        response = self.assert_json_object(
            self.api.request("DELETE", "/orders", query={"externalId": order["externalId"]}), 200
        )
        self.assertTrue(response["success"])

        missing = self.assert_json_object(
            self.api.request("GET", "/orders", query={"externalId": order["externalId"]}), 404
        )
        self.assertFalse(missing["success"])

    def test_getxml_requires_invoice_keys(self):
        response = self.api.request("POST", "/getxml", payload={})
        self.assertEqual(response.status, 400, response.body.decode("utf-8", "replace"))

    def test_delivery_financial_events_requires_invoice_access_key(self):
        if os.getenv("HB_ENABLE_DELIVERY_FINANCIAL_EVENT_TESTS", "").lower() != "true":
            self.skipTest("A rota precisa estar publicada em homologação; habilite com HB_ENABLE_DELIVERY_FINANCIAL_EVENT_TESTS=true")
        response = self.api.request(
            "POST",
            "/incidents",
            payload={
                "eventId": "contract-test-001",
                "eventType": "DO_NOT_PROTEST",
                "occurredAt": "2026-10-24T14:30:00-03:00",
                "invoice": {"number": "000123456", "series": "1"},
                "bankAccount": {"bankCode": "341", "agency": "2731", "account": "03199"},
            },
        )
        self.assertEqual(response.status, 400, response.body.decode("utf-8", "replace"))
        self.assertIn("accessKey", response.json()["message"])

    def test_delivery_financial_events_accepts_all_types_before_invoice_lookup(self):
        if os.getenv("HB_ENABLE_DELIVERY_FINANCIAL_EVENT_TESTS", "").lower() != "true":
            self.skipTest("A rota precisa estar publicada em homologação; habilite com HB_ENABLE_DELIVERY_FINANCIAL_EVENT_TESTS=true")

        event_types = ("DO_NOT_PROTEST", "EXTEND_DUE_DATE", "REQUEST_BANK_WRITE_OFF")
        for event_type in event_types:
            payload = {
                "eventId": "contract-no-title-" + event_type.lower(),
                "eventType": event_type,
                "occurredAt": "2026-10-24T14:30:00-03:00",
                "invoice": {"number": "999999999", "series": "ZZ", "accessKey": "0" * 44},
                "bankAccount": {"bankCode": "341", "agency": "2731", "account": "03199"},
            }
            if event_type == "EXTEND_DUE_DATE":
                payload["newDueDate"] = "2026-11-24"

            response = self.api.request("POST", "/incidents", payload=payload)
            self.assertEqual(response.status, 404, response.body.decode("utf-8", "replace"))
            self.assertIn("sem titulo elegivel", response.json()["message"].lower())

    def test_delivery_financial_events_rejects_invalid_contract_inputs(self):
        if os.getenv("HB_ENABLE_DELIVERY_FINANCIAL_EVENT_TESTS", "").lower() != "true":
            self.skipTest("A rota precisa estar publicada em homologação; habilite com HB_ENABLE_DELIVERY_FINANCIAL_EVENT_TESTS=true")

        base_payload = {
            "eventId": "contract-invalid-input",
            "eventType": "DO_NOT_PROTEST",
            "occurredAt": "2026-10-24T14:30:00-03:00",
            "invoice": {"number": "999999999", "series": "ZZ", "accessKey": "0" * 44},
            "bankAccount": {"bankCode": "341", "agency": "2731", "account": "03199"},
        }
        invalid_cases = []

        invalid_cases.append(({"eventId": "contract-missing-objects"}, "objetos invoice e bankaccount"))

        payload = dict(base_payload)
        payload["eventId"] = ""
        invalid_cases.append((payload, "eventId"))

        payload = dict(base_payload)
        payload["eventId"] = "invalid!event"
        invalid_cases.append((payload, "eventId"))

        payload = dict(base_payload)
        payload["eventType"] = "UNKNOWN_EVENT"
        invalid_cases.append((payload, "eventType"))

        payload = dict(base_payload)
        payload["occurredAt"] = ""
        invalid_cases.append((payload, "occurredAt"))

        payload = dict(base_payload)
        payload["occurredAt"] = "not-a-date"
        invalid_cases.append((payload, "occurredAt"))

        payload = dict(base_payload)
        payload["invoice"] = {"number": "999999999", "series": "ZZ"}
        invalid_cases.append((payload, "accesskey"))

        payload = dict(base_payload)
        payload["bankAccount"] = {"bankCode": "001", "agency": "2731", "account": "03199"}
        invalid_cases.append((payload, "bankAccount"))

        payload = dict(base_payload)
        payload["bankAccount"] = {"bankCode": "341", "account": "03199"}
        invalid_cases.append((payload, "bankAccount"))

        payload = dict(base_payload)
        payload["eventType"] = "EXTEND_DUE_DATE"
        invalid_cases.append((payload, "newDueDate"))

        payload = dict(base_payload)
        payload["eventType"] = "EXTEND_DUE_DATE"
        payload["newDueDate"] = "24/11/2026"
        invalid_cases.append((payload, "newDueDate"))

        for payload, expected_message in invalid_cases:
            response = self.api.request("POST", "/incidents", payload=payload)
            self.assertEqual(response.status, 400, response.body.decode("utf-8", "replace"))
            self.assertIn(expected_message.lower(), response.json()["message"].lower())

    def test_products_requires_id(self):
        payload = self.assert_json_object(self.api.request("GET", "/products/get_id"), 500)
        self.assertEqual(payload["errorId"], "ID001")

    def test_products_get_all(self):
        payload = self.assert_json_object(self.api.request("GET", "/products/get_all", query={"limit": 1, "page": 1}), 200)
        self.assertIn("meta", payload)

    def test_taxinvoices_get(self):
        response = self.api.request("GET", "/taxinvoices", query={"company": "01", "branch": "01", "page": 1, "pageSize": 1})
        self.assertIn(response.status, (200, 404), response.body.decode("utf-8", "replace"))
        self.assertIsInstance(response.json(), dict)

    def test_taxinvoices_post_and_put_invalid_payload(self):
        for method in ("POST", "PUT"):
            payload = self.assert_json_object(self.api.request(method, "/taxinvoices", payload={}), 400)
            self.assertEqual(payload["objects"][0]["errorId"], "NEW004")

    def test_taxinvoices_update_and_clear_tracking(self):
        query = "SELECT TOP 1 F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA FROM SF2010 WHERE D_E_L_E_T_ = ' ' AND RTRIM(F2_XOBJECT) = '' AND RTRIM(F2_ZZIDREM) = '' ORDER BY R_E_C_N_O_ DESC"
        selected = self.assert_json_object(
            self.api.request("POST", "/restqry/consulta", payload={"QUERY": query, "ORDEM": "F2_DOC", "PAGINA": 1, "PORPAGINA": 1}),
            201,
        )["RETORNOS"][0]
        external_object = "AT" + secrets.token_hex(6).upper()
        external_shipment = "RM" + secrets.token_hex(6).upper()
        invoice = {
            "tabela": "SF2",
            "filial": selected["F2_FILIAL"].strip(),
            "documento": selected["F2_DOC"].strip(),
            "serie": selected["F2_SERIE"].strip(),
            "cliente": selected["F2_CLIENTE"].strip(),
            "loja": selected["F2_LOJA"].strip(),
            "idObjeto": external_object,
            "idRemessa": external_shipment,
        }
        lookup = "SELECT F2_XOBJECT, F2_ZZIDREM FROM SF2010 WHERE D_E_L_E_T_ = ' ' AND F2_FILIAL = '" + invoice["filial"] + "' AND F2_DOC = '" + invoice["documento"] + "' AND F2_SERIE = '" + invoice["serie"] + "' AND F2_CLIENTE = '" + invoice["cliente"] + "' AND F2_LOJA = '" + invoice["loja"] + "'"

        try:
            response = self.assert_json_object(self.api.request("POST", "/taxinvoices", payload={"objetos": [invoice]}), 200)
            self.assertIn("Gravado com sucesso", response["objects"][0]["message"])
            saved = self.assert_json_object(
                self.api.request("POST", "/restqry/consulta", payload={"QUERY": lookup, "ORDEM": "F2_XOBJECT", "PAGINA": 1, "PORPAGINA": 1}),
                201,
            )["RETORNOS"][0]
            self.assertEqual(saved["F2_XOBJECT"].strip(), external_object)
            self.assertEqual(saved["F2_ZZIDREM"].strip(), external_shipment)
        finally:
            cleared = self.assert_json_object(self.api.request("PUT", "/taxinvoices", payload={"objetos": [invoice]}), 200)
            self.assertIn("Deletado com sucesso", cleared["objects"][0]["message"])

        cleared = self.assert_json_object(
            self.api.request("POST", "/restqry/consulta", payload={"QUERY": lookup, "ORDEM": "F2_XOBJECT", "PAGINA": 1, "PORPAGINA": 1}),
            201,
        )["RETORNOS"][0]
        self.assertEqual(cleared["F2_XOBJECT"].strip(), "")
        self.assertEqual(cleared["F2_ZZIDREM"].strip(), "")

    def test_romaneios_get(self):
        self.assert_json_object(self.api.request("GET", "/romaneios", query={"page": 1, "pageSize": 1}), 200)


class CallCenterContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        missing = []
        if not os.getenv("HB_API_BASE_URL"):
            missing.append("HB_API_BASE_URL")
        has_token = bool(os.getenv("HB_API_TOKEN"))
        has_credentials = bool(os.getenv("HB_TOKEN_USERNAME")) and bool(os.getenv("HB_TOKEN_PASSWORD"))
        if not has_token and not has_credentials:
            missing.append("HB_API_TOKEN ou HB_TOKEN_USERNAME/HB_TOKEN_PASSWORD")
        if missing:
            raise unittest.SkipTest("Variaveis ausentes: " + ", ".join(missing))
        cls.api = ApiClient()

    def assert_json_object(self, response, expected_status):
        self.assertEqual(response.status, expected_status, response.body.decode("utf-8", "replace"))
        payload = response.json()
        self.assertIsInstance(payload, dict)
        return payload

    def test_post_rejects_missing_routine(self):
        payload = self.assert_json_object(self.api.request("POST", "/callcenter", payload={}), 400)
        self.assertFalse(payload["success"])
        self.assertIn("rotina", payload["message"])

    def test_put_rejects_missing_routine(self):
        payload = self.assert_json_object(self.api.request("PUT", "/callcenter", payload={}), 400)
        self.assertFalse(payload["success"])
        self.assertIn("rotina", payload["message"])

    def test_post_rejects_missing_header(self):
        payload = self.assert_json_object(
            self.api.request("POST", "/callcenter", payload={"rotina": "1"}),
            400,
        )
        self.assertFalse(payload["success"])
        self.assertIn("cabecalho", payload["message"])

    def test_post_rejects_incomplete_process_status_pair(self):
        payload = self.assert_json_object(
            self.api.request(
                "POST",
                "/callcenter",
                payload={"rotina": "2", "cabecalho": {"processStatusCode": "000013"}},
            ),
            400,
        )
        self.assertFalse(payload["success"])
        self.assertIn("processStatusCode", payload["message"])
        self.assertIn("processStatusDescription", payload["message"])

    def test_put_rejects_missing_header(self):
        payload = self.assert_json_object(
            self.api.request("PUT", "/callcenter", payload={"rotina": "1"}),
            400,
        )
        self.assertFalse(payload["success"])
        self.assertIn("cabecalho", payload["message"])

    def test_post_creates_attendance_from_homologation_payload(self):
        if os.getenv("HB_ENABLE_CALLCENTER_CREATE_TESTS", "").lower() != "true":
            self.skipTest("Defina HB_ENABLE_CALLCENTER_CREATE_TESTS=true para criar um atendimento")

        payload_path = os.path.join(os.path.dirname(__file__), "callcenter_create_payload.json")
        with open(payload_path, encoding="utf-8") as payload_file:
            request_payload = json.load(payload_file)

        response_payload = self.assert_json_object(
            self.api.request("POST", "/callcenter", payload=request_payload),
            200,
        )
        self.assertTrue(response_payload["success"], response_payload["message"])
        self.assertIn("incluido com sucesso", response_payload["message"].lower())


class CallCenterPayloadTests(unittest.TestCase):
    def test_homologation_payload_has_required_envelope(self):
        payload_path = os.path.join(os.path.dirname(__file__), "callcenter_create_payload.json")
        with open(payload_path, encoding="utf-8") as payload_file:
            payload = json.load(payload_file)

        self.assertEqual(payload["empresa"], "01")
        self.assertEqual(payload["branch"], "01")
        self.assertEqual(payload["rotina"], "2")
        self.assertIsInstance(payload["cabecalho"], dict)
        self.assertIsInstance(payload["itens"], list)
        self.assertTrue(payload["itens"])
        self.assertEqual(payload["cabecalho"]["processStatusCode"], "000013")
        self.assertEqual(payload["cabecalho"]["processStatusDescription"], "NAO ATENDIDO")
        self.assertEqual(payload["cabecalho"]["oparation"], "2")
        self.assertEqual(payload["cabecalho"]["customerCode"], "C05863")
        self.assertEqual(payload["itens"][0]["productCode"], "10105380868032")
        self.assertEqual(payload["itens"][0]["operationCode"], "7Y0")
        self.assertEqual(payload["itens"][0]["cfopCode"], "6910")


class EjectyTitleContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        base_url = os.getenv("EJECTY_API_BASE_URL", "").strip()
        if not base_url:
            raise unittest.SkipTest("Defina EJECTY_API_BASE_URL para testar EJTitulo")
        if not os.getenv("HB_TOKEN_USERNAME") or not os.getenv("HB_TOKEN_PASSWORD"):
            raise unittest.SkipTest("Variaveis OAuth ausentes para testar EJTitulo")

        original_base_url = os.environ.get("HB_API_BASE_URL")
        os.environ["HB_API_BASE_URL"] = base_url
        try:
            cls.api = ApiClient(base_url)
        finally:
            if original_base_url is None:
                del os.environ["HB_API_BASE_URL"]
            else:
                os.environ["HB_API_BASE_URL"] = original_base_url
        cls.headers = {"TENANTID": os.getenv("EJECTY_TENANT_ID", "01,01")}

    def assert_json_object(self, response, expected_status):
        self.assertEqual(response.status, expected_status, response.body.decode("utf-8", "replace"))
        payload = response.json()
        self.assertIsInstance(payload, dict)
        return payload

    def test_ejtitulo_get_first_page(self):
        payload = self.assert_json_object(
            self.api.request("GET", "/EJTitulo", query={"nPag": 1}, extra_headers=self.headers),
            200,
        )
        self.assertIn("TE_TITULO", payload)
        self.assertIsInstance(payload["TE_TITULO"], list)
        self.assertIn("PaginalAtual", payload)
        self.assertIn("TotalDePaginas", payload)

    def test_ejtitulo_get_empty_page(self):
        payload = self.assert_json_object(
            self.api.request("GET", "/EJTitulo", query={"nPag": 999999}, extra_headers=self.headers),
            200,
        )
        self.assertIn("TE_TITULO", payload)


class GenTokenContractTests(unittest.TestCase):
    def test_oauth_password_grant_returns_access_token(self):
        required = ("HB_API_BASE_URL", "HB_TOKEN_USERNAME", "HB_TOKEN_PASSWORD")
        missing = [name for name in required if not os.getenv(name)]
        if missing:
            self.skipTest("Variaveis OAuth ausentes: " + ", ".join(missing))

        self.assertTrue(get_oauth_token())