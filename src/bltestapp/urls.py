from baseline.routers import PrefixBasenameSimpleRouter

from .views import WidgetViewSet

router = PrefixBasenameSimpleRouter()
router.register(r"widgets", WidgetViewSet)

urlpatterns = router.urls
