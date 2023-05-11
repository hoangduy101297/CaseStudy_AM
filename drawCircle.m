function [x_ret, y_ret, z_ret] = drawCircle(rad,pos,n,color,angle)
    %https://demonstrations.wolfram.com/ParametricEquationOfACircleIn3D/
    %draws a 3D circle at position pos with radius rad, normal to the
    %circle n, and color color.
    phi = atan2(n(2),n(1)); %azimuth angle, in [-pi, pi]
    theta = atan2(sqrt(n(1)^2 + n(2)^2) ,n(3));% zenith angle, in [0,pi]    
    t = linspace(pi/2,angle,21);
    x = pos(1)- rad*( cos(t)*sin(phi) + sin(t)*cos(theta)*cos(phi) );
    y = pos(2)+ rad*( cos(t)*cos(phi) - sin(t)*cos(theta)*sin(phi) );
    z = pos(3)+ rad*sin(t)*sin(theta);
    plot3(x,y,z,color)
    grid on
    x_ret = x;
    y_ret = y;
    z_ret = z;
end