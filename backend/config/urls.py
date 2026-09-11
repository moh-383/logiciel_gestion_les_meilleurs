from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/auth/", include("accounts.auth_urls")),
    path("api/v1/", include("accounts.urls")),
    path("api/v1/", include("core.urls")),
    path("api/v1/", include("eleves.urls")),
    path("api/v1/", include("paiements.urls")),
    path("api/v1/", include("notifications.urls")),
    path("api/v1/", include("communication.urls")),
    path("api/v1/", include("enseignants.urls")),
    path("api/v1/", include("programmes.urls")),
]
