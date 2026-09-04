from rest_framework.routers import DefaultRouter

from .views import PermissionViewSet, PosteViewSet, SiteViewSet

router = DefaultRouter(trailing_slash=False)
router.register("permissions", PermissionViewSet, basename="permission")
router.register("postes", PosteViewSet, basename="poste")
router.register("sites", SiteViewSet, basename="site")
urlpatterns = router.urls
