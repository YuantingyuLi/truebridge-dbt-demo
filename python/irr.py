"""
irr.py

Utility functions for calculating Internal Rate of Return (IRR),
a core performance metric in venture capital fund analysis.

IRR is the discount rate that makes the Net Present Value (NPV)
of all cash flows equal to zero. It is solved iteratively using
the Newton-Raphson method, since no closed-form solution exists.
"""


def npv(rate: float, cash_flows: list[float]) -> float:
    """
    Calculate the Net Present Value (NPV) of a series of cash flows
    at a given discount rate.

    Args:
        rate: Discount rate (e.g. 0.1 for 10%)
        cash_flows: List of cash flows ordered by period.
                    Negative values = capital outflows (contributions).
                    Positive values = capital inflows (distributions).

    Returns:
        Net present value as a float.
    """
    return sum(cf / (1 + rate) ** t for t, cf in enumerate(cash_flows))


def npv_derivative(rate: float, cash_flows: list[float]) -> float:
    """
    Calculate the derivative of NPV with respect to rate.
    Used by the Newton-Raphson method to find the next rate estimate.

    Args:
        rate: Current rate estimate.
        cash_flows: List of cash flows ordered by period.

    Returns:
        Derivative of NPV at the given rate.
    """
    return sum(
        -t * cf / (1 + rate) ** (t + 1)
        for t, cf in enumerate(cash_flows)
        if t > 0
    )


def calculate_irr(
    cash_flows: list[float],
    initial_guess: float = 0.1,
    tolerance: float = 1e-10,
    max_iterations: int = 1000
) -> float | None:
    """
    Calculate the Internal Rate of Return (IRR) for a series of cash flows
    using the Newton-Raphson iterative method.

    Args:
        cash_flows: List of cash flows ordered by period.
                    Must contain at least one negative and one positive value.
                    Example: [-50_000_000, 0, 0, 80_000_000]
                    (invested $50M at t=0, received $80M at t=3)
        initial_guess: Starting estimate for the IRR (default: 10%).
        tolerance: Convergence threshold — stops iterating when NPV
                   is within this value of zero (default: 1e-6).
        max_iterations: Maximum number of iterations before giving up
                        (default: 1000).

    Returns:
        IRR as a float (e.g. 0.1696 for 16.96%), or None if the
        algorithm fails to converge.

    Raises:
        ValueError: If cash_flows is empty or contains no sign changes
                    (IRR is undefined without both inflows and outflows).
    """
    if not cash_flows:
        raise ValueError("cash_flows must not be empty.")

    has_negative = any(cf < 0 for cf in cash_flows)
    has_positive = any(cf > 0 for cf in cash_flows)

    if not has_negative or not has_positive:
        raise ValueError(
            "cash_flows must contain at least one negative value "
            "(contribution) and one positive value (distribution). "
            "IRR is undefined without both inflows and outflows."
        )

    rate = initial_guess

    for _ in range(max_iterations):
        current_npv = npv(rate, cash_flows)
        derivative = npv_derivative(rate, cash_flows)

        if abs(derivative) < 1e-12:
            return None

        next_rate = rate - current_npv / derivative

        if abs(next_rate - rate) < tolerance:
            return round(next_rate, 10)

        rate = next_rate

    return None