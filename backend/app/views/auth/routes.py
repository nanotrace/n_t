from . import bp

@bp.route("/login")
def login():
    return "auth.nanotrace.org/login is live"
