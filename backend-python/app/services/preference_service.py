"""User preference vector management."""

from app.config.mongo import get_mongo_db
from app.ml.feature_engineering import extract_user_features, build_preference_vector


async def get_user_preference_vector(user_id: str, pg_user: dict) -> list[float]:
    """Load user profile from MongoDB and build preference vector."""
    db = get_mongo_db()
    profile = await db.userprofiles.find_one({"userId": user_id})
    features = extract_user_features(pg_user, profile)
    return build_preference_vector(features), features


async def update_preference_after_session(
    user_id: str,
    session_features: dict,
    rating_given: float | None = None,
) -> None:
    """Incrementally update user preference vector after a session."""
    db = get_mongo_db()
    profile = await db.userprofiles.find_one({"userId": user_id})
    if not profile:
        return

    pv = profile.get("preference_vector", {})
    cuisine_weights = pv.get("cuisine_weights", {})
    food_cat = session_features.get("food_category", "")

    if food_cat:
        current = float(cuisine_weights.get(food_cat, 0.5))
        cuisine_weights[food_cat] = min(1.0, current + 0.05)

    update_doc = {"preference_vector.cuisine_weights": cuisine_weights}

    if rating_given is not None:
        current_avg = float(pv.get("avg_session_rating_given", 3.0))
        new_avg = (current_avg * 0.9) + (rating_given * 0.1)
        update_doc["preference_vector.avg_session_rating_given"] = new_avg

    fav_cuisines = profile.get("session_history_summary", {}).get("favorite_cuisines", [])
    if food_cat and food_cat not in fav_cuisines:
        fav_cuisines = ([food_cat] + fav_cuisines)[:5]
        update_doc["session_history_summary.favorite_cuisines"] = fav_cuisines

    await db.userprofiles.update_one({"userId": user_id}, {"$set": update_doc})
