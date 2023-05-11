alpha = 0.05;
R_casing_curve = 21;
R_shell_start = 2; %related to clearance
R_inner = 15;
shell_thickness = 1;
theta = linspace(0,2*pi,21);
R_shaft = 5;


r = R_casing_curve*exp(alpha*theta);

%R_outlet = 0.5*(r(201)-r(1));
R_outlet = 5;
%R_shell = linspace(R_shell_start,R_outlet,201);
R_shell = R_outlet*ones(1,21);
r_plot = r - R_shell;

%polarplot(theta,r);
z = zeros(1,21);
[x,y] = pol2cart(theta,r);
[x_plot,y_plot] = pol2cart(theta,r_plot);
plot3(x,y,z,'Color','b')
grid on
axis equal
hold on

outlet_y = linspace(y(1,21),20,21);
outlet_x = x(1,21)*ones(1,21);
outlet_x_plot = (x(1,21)-R_outlet)*ones(1,21);


plot3(outlet_x,outlet_y,z(1,1:21),'Color','b');
v = zeros(21,3);
x_shell = zeros(222,21);
y_shell = zeros(222,21);
z_shell = zeros(222,21);

for i = 1:21   
    v = [-sin(theta(i)) cos(theta(i)) 0];
    [x_shell(i,:), y_shell(i,:), z_shell(i,:)] = drawCircle(R_outlet,[x_plot(i),y_plot(i),z(i)],v,'r',3*pi/2);
    [x_shell_thick(i,:), y_shell_thick(i,:), z_shell_thick(i,:)] = drawCircle(R_outlet+shell_thickness,[x_plot(i),y_plot(i),z(i)],v,'r',3*pi/2);
end



for i = 1:21   
    v_outlet = [0 1 0];
    %temp to make the graph looks nice
    if(outlet_y(i) > y(1,1))
        [x_shell(i+21,:), y_shell(i+21,:), z_shell(i+21,:)] = drawCircle(R_outlet,[outlet_x_plot(i),outlet_y(i),z(i)],v_outlet,'r',pi/2+2*pi);
    else
        [x_shell(i+21,:), y_shell(i+21,:), z_shell(i+21,:)] = drawCircle(R_outlet,[outlet_x_plot(i),outlet_y(i),z(i)],v_outlet,'r',3*pi/2);
    end
end

%plot([0,0],'*')


r_inner = R_inner*ones(1,21);
[x_inner, y_inner] = pol2cart(theta,r_inner);
plot3(x_inner,y_inner,z, 'Color','b');

full_theta = linspace(0,2*pi,21);

%top hole
for i = 1:21   
    v = [-sin(full_theta(i)) cos(full_theta(i)) 0];
    [x_inner_shell(i,:), y_inner_shell(i,:), z_inner_shell(i,:)] = drawCircle(R_outlet,[x_inner(i),y_inner(i),z(i)],v,'b',pi/5);
    [x_inner_shell_thick(i,:), y_inner_shell_thick(i,:), z_inner_shell_thick(i,:)] = drawCircle(R_outlet+shell_thickness,[x_inner(i),y_inner(i),z(i)],v,'b',pi/5);
end

for i = 1:21  
    x_shaft(i) = R_shaft*cos(full_theta(i));
    y_shaft(i) = R_shaft*sin(full_theta(i));
    z_shaft(i) = z_shell(1,21);
    x_shaft_thick(i) = R_shaft*cos(full_theta(i));
    y_shaft_thick(i) = R_shaft*sin(full_theta(i));
    z_shaft_thick(i) = z_shell_thick(1,21);
end

plot3(x_shaft, y_shaft,z_shaft);
plot3(x_shaft_thick , y_shaft_thick ,z_shaft_thick);

%print the contour to file 
fileID = fopen('casing_contour.txt','w');
fprintf(fileID,'outer = {\n');
for i = 1:21   
    fprintf(fileID,'{');

    % shell
    for j = 21:-1:1
        fprintf(fileID,'v(%f,%f,%f)',x_shell(i,j), y_shell(i,j), z_shell(i,j));
        %if j ~= 21
            fprintf(fileID,',');
        %end    
    end

    % inner curve
    for j = 1:21
        fprintf(fileID,'v(%f,%f,%f)',x_inner_shell(i,j), y_inner_shell(i,j), z_inner_shell(i,j));
        %if j ~= 21
            fprintf(fileID,',');
        %end    
    end

    % inner curve thickness
    for j = 21:-1:1
        fprintf(fileID,'v(%f,%f,%f)',x_inner_shell_thick(i,j), y_inner_shell_thick(i,j), z_inner_shell_thick(i,j));
        %if j ~= 21
            fprintf(fileID,',');
        %end    
    end

    % outer shell thickness line
    for j = 1:21
        fprintf(fileID,'v(%f,%f,%f)',x_shell_thick(i,j), y_shell_thick(i,j), z_shell_thick(i,j));
        %if j ~= 21
            fprintf(fileID,',');
        %end    
    end
    
    % bottom shaft hole
    fprintf(fileID,'v(%f,%f,%f),',x_shaft_thick(i), y_shaft_thick(i), z_shaft_thick(i));

    % shaft hole (inside)
    fprintf(fileID,'v(%f,%f,%f)',x_shaft(i), y_shaft(i), z_shaft(i));

    fprintf(fileID,'}');

    if i ~= 21
            fprintf(fileID,',\n');
    end
end

fprintf(fileID,'\n}\n');
fclose(fileID);


% fileID = fopen('casing_contour.txt','w');
% fprintf(fileID,'contours = {\n');
% for i = 1:21   
%     fprintf(fileID,'{');
% 
%     for j = 1:21
%         fprintf(fileID,'v(%f,%f,%f)',x_inner_shell(i,j), y_inner_shell(i,j), z_inner_shell(i,j));
%         %if j ~= 21
%             fprintf(fileID,',');
%        % end    
%     end
% 
%     for j = 21:-1:1
%         fprintf(fileID,'v(%f,%f,%f)',x_inner_shell_thick(i,j), y_inner_shell_thick(i,j), z_inner_shell_thick(i,j));
%         if j ~= 1
%             fprintf(fileID,',');
%         end    
%     end
% 
%     fprintf(fileID,'}');
% 
%     if i ~= 21
%             fprintf(fileID,',\n');
%     end
% end
% fprintf(fileID,'\n}\n');
% fclose(fileID);



%xlabel('x (mm)');
%ylabel('y (mm)');
%zlabel('z (mm)');
%title('Geometry of the volute casing')
%grid on