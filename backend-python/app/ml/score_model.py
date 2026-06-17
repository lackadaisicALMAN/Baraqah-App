"""Baraqah Score formula and decay model."""

from datetime import datetime, timedelta, timezone
from typing import Any


# Component weights for composite score
SCORE_WEIGHTS = {
    "attendance_rate": 0.30,
    "host_reliability": 0.20,
    "peer_reviews": 0.20,
    "session_volume": 0.15,
    "social_trust": 0.15,
}

# Event deltas (mirrors PostgreSQL score_event_type effects)
EVENT_DELTAS = {
    "SESSION_COMPLETED": 1.5,
    "HOST_COMPLETED": 2.0,
    "NO_SHOW": -5.0,
    "LATE_CANCELLATION": -3.0,
    "REVIEW_RECEIVED": 0.5,
    "VOUCHED_BY_FRIEND": 0.25,
}


def clamp_score(score: float, min_val: float = 0.0, max_val: float = 100.0) -> float:
    return max(min_val, min(max_val, score))


def compute_attendance_rate(total_sessions: int, total_no_shows: int) -> float:
    """Attendance reliability component (0-100)."""
    if total_sessions == 0:
        return 50.0
    rate = (total_sessions - total_no_shows) / total_sessions
    return clamp_score(rate * 100)


def compute_host_reliability(total_hosted: int, total_sessions: int) -> float:
    """Hosting experience component (0-100)."""
    if total_hosted == 0:
        return 50.0
    host_ratio = total_hosted / max(total_sessions, 1)
    return clamp_score(50 + host_ratio * 50)


def compute_session_volume(total_sessions: int) -> float:
    """Experience volume with diminishing returns."""
    return clamp_score(min(total_sessions * 3, 80) + 20)


def compute_peer_review_component(review_events: list[dict]) -> float:
    """Score from review events."""
    if not review_events:
        return 50.0
    positive = sum(1 for e in review_events if e.get("delta", 0) > 0)
    return clamp_score(50 + positive * 5)


def compute_social_trust(friend_vouches: int, total_friends: int) -> float:
    """Social graph trust component."""
    if total_friends == 0:
        return 50.0
    return clamp_score(50 + min(friend_vouches * 3, 30) + min(total_friends, 20))


def apply_time_decay(score: float, last_event_at: datetime | None) -> float:
    """Apply decay for inactive users — 1% per 30 days of inactivity."""
    if not last_event_at:
        return score

    now = datetime.now(timezone.utc)
    if last_event_at.tzinfo is None:
        last_event_at = last_event_at.replace(tzinfo=timezone.utc)

    days_inactive = (now - last_event_at).days
    if days_inactive <= 30:
        return score

    decay_periods = (days_inactive - 30) // 30
    decay_factor = 0.99 ** decay_periods
    return clamp_score(score * decay_factor)


def compute_baraqah_score(
    user_stats: dict[str, Any],
    score_events: list[dict],
    social_stats: dict[str, int],
) -> tuple[float, list[dict]]:
    """
    Compute composite Baraqah Score from components.
    Returns (final_score, component_breakdown).
    """
    review_events = [e for e in score_events if e.get("event_type") == "REVIEW_RECEIVED"]
    vouch_events = [e for e in score_events if e.get("event_type") == "VOUCHED_BY_FRIEND"]

    components = {
        "attendance_rate": compute_attendance_rate(
            user_stats.get("total_sessions", 0),
            user_stats.get("total_no_shows", 0),
        ),
        "host_reliability": compute_host_reliability(
            user_stats.get("total_hosted", 0),
            user_stats.get("total_sessions", 0),
        ),
        "peer_reviews": compute_peer_review_component(review_events),
        "session_volume": compute_session_volume(user_stats.get("total_sessions", 0)),
        "social_trust": compute_social_trust(
            len(vouch_events),
            social_stats.get("friend_count", 0),
        ),
    }

    weighted_sum = sum(
        components[name] * SCORE_WEIGHTS[name] for name in SCORE_WEIGHTS
    )

    last_event = None
    if score_events:
        timestamps = [e.get("created_at") for e in score_events if e.get("created_at")]
        if timestamps:
            last_event = max(
                t if isinstance(t, datetime) else datetime.fromisoformat(str(t))
                for t in timestamps
            )

    final_score = apply_time_decay(weighted_sum, last_event)
    final_score = clamp_score(final_score)

    breakdown = [
        {
            "name": name,
            "value": round(components[name], 2),
            "weight": SCORE_WEIGHTS[name],
            "contribution": round(components[name] * SCORE_WEIGHTS[name], 2),
        }
        for name in SCORE_WEIGHTS
    ]

    return round(final_score, 2), breakdown
