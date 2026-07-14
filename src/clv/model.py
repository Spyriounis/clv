"""Model definitions for the ZILN customer-lifetime-value network.

The Zero-Inflated LogNormal (ZILN) DNN and its loss will be implemented here.

Planned architecture (Figure 3 of the paper):

    input features -> shared hidden layers -> 3 logits
        p     : probability of a returning (nonzero-LTV) customer  -> sigmoid
        mu    : lognormal mean parameter                           -> identity
        sigma : lognormal std-dev parameter                        -> softplus

ZILN loss:

    L = BCE(1{x > 0}; p) + 1{x > 0} * Lognormal(x; mu, sigma)

Expected LTV point prediction:

    E[X] = p * exp(mu + sigma**2 / 2)

No implementation yet — this module is a scaffold placeholder.
"""
