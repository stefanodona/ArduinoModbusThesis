function [ y ] = isolve( h,f,ker )
 % Matlab Code to solve Volterra Integral Equations with Convolution Kernel 
 % using Laplace Transforms
 %
 % h=h(x), h(x)=1 => 2nd kind & h(x)=0 => 1st kind
 %
 % f=f(x), f(x)=0 => homogeneous & non homogeneous otherwise
 %
 % ker=ker(x,t), kernel of integral equation
 %
 % when ker(x,t)=ker(x-t), we say that it is a convolution kernel
 %
 % The general form is :
 %
 % h(x)y(x)=f(x)+int(ker(x-t)*y(t),0,x)dt
 %
 % isolve accepts h(x), f(x) and ker(x-t) from the user and solves the
 % integral equation and gives the output in y(x).
 %
 % Example :
 % Take the following Volterra 1st kind nonhomogeneous Integral Equation with
 % difference kernel
 %
 % sin(x)=int(exp(x-t)y(t),0,x)dt
 %
 % Command window :
 %
 % >> syms x t s
 % >> isolve(0,sin(x),exp(x-t))
 % ans =
 % cos(x) - sin(x)
 %
 % While running the code make sure you symbolically declare the 
 % following variables in the command window ; x t and s 
 % i.e. syms x t s
 
 syms Y y x s t
 % Check whether the Integral Equation is 1st kind or 2nd kind
if h==1||h==0
    F=laplace(f,x,s);
    KER=laplace(subs(ker,t,0),x,s);
    % Case : Volterra 2nd kind
    if h==1
        Y=solve(F+KER*Y==Y,Y);
        y=simple(ilaplace(Y,s,x));
         ezplot(y);
    % Case : Volterra 1st kind
    elseif h==0
        Y=solve(F-KER*Y==0,Y);
        y=simple(ilaplace(Y,s,x));
        ezplot(y);
    end
else
    % Display error message if the equation is neither 1st kind or 2nd kind
 disp('The equation is invalid !');
end
end