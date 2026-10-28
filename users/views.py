from django.shortcuts import render, redirect
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login
from django.contrib import messages
from django.contrib.auth.decorators import login_required

def welcome(request):
    return render(request, 'welcome.html')

def login_view(request):
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)

        if user is not None:
            login(request, user)
            # CHANGE THIS: Redirect to 'dashboard' instead of 'welcome'
            return redirect('dashboard') 
        else:
            messages.error(request, "Invalid username or password.")
            return redirect('login')

    return render(request, 'login.html')

# --- Add this new view at the bottom ---
@login_required(login_url='login')
def dashboard(request):
    # The @login_required decorator ensures only logged-in users can view this page
    return render(request, 'dashboard.html')
def register(request):
    if request.method == 'POST':
        # 1. Capture the data from the HTML form attributes
        username = request.POST.get('username')
        email = request.POST.get('email')
        password = request.POST.get('password')
        area_id = request.POST.get('area') # Captures the selected dropdown value

        try:
            # 2. Create the user in the database (this automatically hashes the password)
            user = User.objects.create_user(username=username, email=email, password=password)
 
            return redirect('login')
            
        except Exception as e:
            # If username exists or another DB error occurs, reload the page with an error
            messages.error(request, f"Registration failed: {e}")
            return redirect('register')


    return render(request, 'register.html')