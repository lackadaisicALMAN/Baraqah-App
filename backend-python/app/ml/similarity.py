"""Cosine and weighted similarity functions."""

import math
from typing import Sequence


def cosine_similarity(vec_a: Sequence[float], vec_b: Sequence[float]) -> float:
    """Compute cosine similarity between two vectors."""
    if len(vec_a) != len(vec_b):
        min_len = min(len(vec_a), len(vec_b))
        vec_a = vec_a[:min_len]
        vec_b = vec_b[:min_len]

    dot = sum(a * b for a, b in zip(vec_a, vec_b))
    mag_a = math.sqrt(sum(a * a for a in vec_a))
    mag_b = math.sqrt(sum(b * b for b in vec_b))

    if mag_a == 0 or mag_b == 0:
        return 0.0

    return dot / (mag_a * mag_b)


def weighted_similarity(
    vec_a: Sequence[float],
    vec_b: Sequence[float],
    weights: Sequence[float] | None = None,
) -> float:
    """Weighted cosine similarity — weights applied before dot product."""
    if weights is None:
        weights = [1.0] * len(vec_a)

    min_len = min(len(vec_a), len(vec_b), len(weights))
    vec_a = vec_a[:min_len]
    vec_b = vec_b[:min_len]
    weights = weights[:min_len]

    weighted_a = [a * w for a, w in zip(vec_a, weights)]
    weighted_b = [b * w for b, w in zip(vec_b, weights)]

    return cosine_similarity(weighted_a, weighted_b)


def cuisine_overlap(
    user_cuisines: dict,
    session_category: str,
    restaurant_tags: list[str],
) -> float:
    """Score cuisine preference overlap (0-1)."""
    if not user_cuisines:
        return 0.5

    scores = []
    all_tags = [session_category] + (restaurant_tags or [])

    for tag in all_tags:
        tag_lower = tag.lower()
        for cuisine, weight in user_cuisines.items():
            if cuisine.lower() in tag_lower or tag_lower in cuisine.lower():
                scores.append(float(weight))

    return sum(scores) / len(scores) if scores else 0.3


def compute_match_reasons(
    user_features: dict,
    session_features: dict,
    similarity: float,
) -> list[str]:
    """Generate human-readable match reasons."""
    reasons = []

    if similarity >= 0.8:
        reasons.append("Strong preference match")

    overlap = cuisine_overlap(
        user_features.get("cuisine_weights", {}),
        session_features.get("food_category", ""),
        session_features.get("cuisine_tags", []),
    )
    if overlap >= 0.7:
        reasons.append(f"Matches your {session_features.get('food_category')} preference")

    if session_features.get("distance_km", 99) < 2:
        reasons.append("Very close to you")

    if session_features.get("host_baraqah_score", 0) >= 70:
        reasons.append("Highly rated host")

    if (
        user_features.get("transport_preference") == "RIDE_TOGETHER"
        and session_features.get("has_ride_available")
    ):
        reasons.append("Ride sharing available")

    pref = user_features.get("preferred_group_size", {"min": 2, "max": 6})
    current = session_features.get("current_attendees", 1)
    if pref["min"] <= current <= pref["max"]:
        reasons.append("Group size fits your preference")

    return reasons or ["Nearby open session"]
