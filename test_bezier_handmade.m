clear all

p0 = [0 5]; %[theta r]
weight1 = 100;
phi1 = 60;

p3 = [270 20]; %[theta r]
weight2 = 150;
phi2 = 45;


p1 = [p0(1,1)+weight1*cosd(phi1) p0(1,2)+weight1*sind(phi1)];
p2 = [p3(1,1)-weight2*cosd(phi2) p3(1,2)+weight2*sind(phi2)];
i = 1;
n = 50;
%P = zeros(1,2);
for t=0:0.01:1
    P(i,:)=  p0*(-t^3 + 3*t^2 - 3*t + 1)...
         + p1*(3*t^3 - 6*t^2 + 3*t)...
         + p2*(-3*t^3 + 3*t^2)...
         + p3*(t^3)
    i = i+1;
end
line(P(:,1),P(:,2), "LineWidth",2,'Color','red')
hold on
grid on
line([p0(1,1) p1(1,1) p2(1,1) p3(1,1)],[p0(1,2) p1(1,2) p2(1,2) p3(1,2)])
axis equal

xlabel('x')
ylabel('y')
title('Bézier Curve')

%figure(2)
%polarplot(deg2rad(P(:,1)),P(:,2))
