import pytest
from backend.src.services.cost_estimator_service import CostEstimatorService

class TestCostEstimator:
    
    def test_madrid_rates_resale(self):
        # Madrid ITP is 6%
        price = 200000
        result = CostEstimatorService.calculate_purchase_costs(price, "MADRID", is_new_construction=False)
        
        expected_tax = price * 0.06
        assert result["tax_amount"] == expected_tax
        assert "ITP (6%)" in result["tax_name"]
        
    def test_catalonia_rates_resale(self):
        # Catalonia ITP is 10%
        price = 300000
        result = CostEstimatorService.calculate_purchase_costs(price, "CATALONIA", is_new_construction=False)
        
        expected_tax = price * 0.10
        assert result["tax_amount"] == expected_tax
        
    def test_new_construction_tax(self):
        # New Construction is fixed 11% (10% IVA + 1% AJD)
        price = 250000
        result = CostEstimatorService.calculate_purchase_costs(price, "MADRID", is_new_construction=True)
        
        expected_tax = price * 0.11
        assert result["tax_amount"] == expected_tax
        assert "IVA" in result["tax_name"]
        
    def test_notary_scale_logic(self):
        # Test low value property
        price_low = 50000
        res_low = CostEstimatorService.calculate_purchase_costs(price_low, "OTHER")
        assert res_low["notary_estimated"] >= 400 # Minimum floor
        
        # Test high value property
        price_high = 1000000
        res_high = CostEstimatorService.calculate_purchase_costs(price_high, "OTHER")
        assert res_high["notary_estimated"] > res_low["notary_estimated"]
        
    def test_mandatory_disclaimer(self):
        price = 100000
        result = CostEstimatorService.calculate_purchase_costs(price, "OTHER")
        assert "legal_disclaimer" in result
        assert len(result["legal_disclaimer"]) > 50
        assert "NO constituye asesoramiento fiscal" in result["legal_disclaimer"]

    def test_api_endpoint_structure(self):
        # Import Router to verify Pydantic Schema integrity if needed
        # Or implicitly tested via Integration Tests later.
        pass
