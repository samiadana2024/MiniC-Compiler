from django.contrib import admin
from django.urls import path
from compiler import views # CHANGE: Imported views from the compiler app

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.index, name='index'), # CHANGE: Base URL loads the IDE
    path('api/compile/', views.compile_code, name='compile_code'), # CHANGE: API for subprocess execution
]