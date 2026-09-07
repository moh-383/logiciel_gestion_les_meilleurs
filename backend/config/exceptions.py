from rest_framework.views import exception_handler


def api_exception_handler(exc, context):
    """Normalise les erreurs HTTP selon le contrat API."""
    response = exception_handler(exc, context)
    if response is None:
        return response
    details = response.data
    if isinstance(details, dict):
        message = details.get("detail")
        if message is None:
            message = "; ".join(
                f"{champ}: {', '.join(str(erreur) for erreur in erreurs)}"
                for champ, erreurs in details.items()
            ) or "Requête invalide."
    else:
        message = "Requête invalide."
    response.data = {"error": _error_code(response.status_code), "message": str(message)}
    return response


def _error_code(status_code):
    return {400: "requete_invalide", 401: "non_authentifiee", 403: "permission_refusee", 404: "introuvable", 409: "conflit", 422: "validation_echouee"}.get(status_code, "erreur_serveur")
