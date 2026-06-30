"""
test_irr.py

Unit tests for IRR calculation utility functions.
Tests cover standard VC cash flow scenarios, edge cases,
and expected error conditions.
"""

import pytest
from irr import calculate_irr, npv


class TestNPV:
    """Tests for the npv() helper function."""

    def test_npv_at_zero_rate(self):
        """At rate=0, NPV should equal the simple sum of cash flows."""
        cash_flows = [-100, 50, 80]
        assert npv(0, cash_flows) == pytest.approx(30, rel=1e-5)

    def test_npv_single_cash_flow(self):
        """NPV of a single cash flow at t=0 equals the cash flow itself."""
        assert npv(0.1, [-100]) == pytest.approx(-100, rel=1e-5)


class TestCalculateIRR:
    """Tests for the calculate_irr() function."""

    def test_simple_two_period(self):
        """
        Basic two-period case: invest $50M at t=0, receive $80M at t=3.
        Expected IRR ≈ 16.96%.
        """
        cash_flows = [-50_000_000, 0, 0, 80_000_000]
        result = calculate_irr(cash_flows)
        assert result is not None
        assert result == pytest.approx(0.1696, rel=1e-2)

    def test_irr_makes_npv_zero(self):
        """
        The IRR, when used as the discount rate, should produce NPV ≈ 0.
        This validates the fundamental definition of IRR.
        """
        cash_flows = [-100_000, 30_000, 40_000, 50_000]
        irr = calculate_irr(cash_flows)
        assert irr is not None
        assert npv(irr, cash_flows) == pytest.approx(0, abs=1e-3)

    def test_multiple_contributions(self):
        """
        Realistic VC scenario: multiple contributions followed by
        a single large distribution.
        """
        cash_flows = [-20_000_000, -30_000_000, 0, 0, 100_000_000]
        irr = calculate_irr(cash_flows)
        assert irr is not None
        assert irr > 0
        assert npv(irr, cash_flows) == pytest.approx(0, abs=1e-2)

    def test_negative_irr(self):
        """
        Loss scenario: invested more than returned.
        IRR should be negative.
        """
        cash_flows = [-100_000, 0, 0, 50_000]
        irr = calculate_irr(cash_flows)
        assert irr is not None
        assert irr < 0

    def test_raises_on_empty_cash_flows(self):
        """Should raise ValueError when cash_flows is empty."""
        with pytest.raises(ValueError, match="must not be empty"):
            calculate_irr([])

    def test_raises_on_all_negative(self):
        """
        Should raise ValueError when there are no positive cash flows
        (no distributions — IRR is undefined).
        """
        with pytest.raises(ValueError, match="at least one negative"):
            calculate_irr([-100, -200, -300])

    def test_raises_on_all_positive(self):
        """
        Should raise ValueError when there are no negative cash flows
        (no contributions — IRR is undefined).
        """
        with pytest.raises(ValueError, match="at least one negative"):
            calculate_irr([100, 200, 300])