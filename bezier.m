%Hello! this will plot Bezier curve for n control points 
%This is a replacement of the program 'Parametic Cubic Bezier Curve'
%submitted before ...Bezier for any number of points ...enjoy 
%clear all 
%clc
 
n=input('Enter no. of points  ');
w=input('Press 1 for entry through mouse or 2 for keyboard repectively-->');
n1=n-1;
if w==1
    axis([0 3/2*pi 0 50])
    grid on
    [p]=ginput(n);
end
if w==2
    [p]=input('Enter co-odinates of points within brackets ->[x1 y1;x2 y2;x3 y3;...;xn yn] ');
     end
    
for    i=0:1:n1
sigma(i+1)=factorial(n1)/(factorial(i)*factorial(n1-i));  % for calculating (x!/(y!(x-y)!)) values 
end
l=[];
UB=[];
for u=0:0.02:1
for d=1:n
UB(d)=sigma(d)*((1-u)^(n-d))*(u^(d-1));
end
l=cat(1,l,UB);                                      %catenation 
end
P=l*p;

line(P(:,1),P(:,2), "LineWidth",2,'Color','red')
line(p(:,1),p(:,2),'Color','blue')
hold on
plot(p(1,1),p(1,2),'*','Color','blue')
plot(p(2,1),p(2,2),'*','Color','blue')
plot(p(3,1),p(3,2),'*','Color','blue')
plot(p(4,1),p(4,2),'*','Color','blue')

xlabel('\theta (rad)');
ylabel('R (mm)');

grid on 
%axis equal

% books for reference on the subject of cad/cam author Roger Adams  ,
% Ibrahim Zeid 
%Prepared by Mechanical engg. student NIT Allahabad , India
% for any questions feel free to mail me at slnarasimhan89@gmail.com