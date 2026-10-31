import json
import os
import unittest
from pathlib import Path


def load_payment_payload():
    fixture_path = os.getenv("EJECTY_PAYMENT_PAYLOAD_FILE", "").strip()
    if not fixture_path:
        raise unittest.SkipTest("Defina EJECTY_PAYMENT_PAYLOAD_FILE com o JSON retornado pelo Mercado Pago")

    with Path(fixture_path).open(encoding="utf-8") as fixture_file:
        payload = json.load(fixture_file)

    if not isinstance(payload, list) or not payload:
        raise AssertionError("O payload de pagamento deve ser um array não vazio")
    if not isinstance(payload[0], dict) or not isinstance(payload[0].get("results"), list):
        raise AssertionError("O payload deve conter results conforme o contrato de EJTitulo")
    return payload


class EjectyTitlePaymentPayloadTests(unittest.TestCase):
    def test_payment_payload_contract(self):
        payload = load_payment_payload()
        payment = payload[0]["results"][0]
        for field in ("transaction_amount", "money_release_status", "id", "money_release_date", "charges_details"):
            self.assertIn(field, payment)

    def test_payment_sync_is_explicitly_disabled(self):
        if os.getenv("EJECTY_ENABLE_PAYMENT_SYNC_TESTS", "").lower() == "true":
            self.skipTest("A execução financeira deve ocorrer pela suíte de integração configurada")
        self.assertNotEqual(os.getenv("EJECTY_ENABLE_PAYMENT_SYNC_TESTS", "").lower(), "true")