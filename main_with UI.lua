view_list = {
	{0, "Full view"},
	{1, "impeller"},
	{2, "volute"}
}

view=ui_radio("View:",view_list)

-- GLobal scale
global_scale=ui_scalar("GLobal scale",3,.1,10)

-- 
-- Parameters for shroud
r_shroud = ui_number("Shroud radius",24,22,30)
h_shroud = ui_number("Shroud height",2,1,5)
h_blade = ui_number("Blade height",5,2,10)

-- Bezier control point for blade centerline
text = ui_number("Blade centerline",0,0,0)
p0_x = ui_number("Start angle",0,0,100)      -- Start angle
p0_y = ui_number("Start radius",5,0,10)     -- Start radius
w1 = ui_number("Weight 1",20,10,30)
alpha1 = ui_number("Alpha 1",15,10,20)
p3_x = ui_number("Wrap angle",300,270,330)    -- Wrap angle
p3_y = ui_number("Stop radius",20,10,25)     -- 
w2 = ui_number("Weight 2",50,40,60)
alpha2 = ui_number("Alpha 2",-10,-15,-5)

-- Bezier control point for blade thickness
text = ui_number("Blade thickness",0,0,0)
--[BUG] - p0_x_r varying doesnt have an impact on the geometry
p0_x_r = ui_number("Start_angle",0,0,100)     -- Start angle
p0_y_r = ui_scalar("Start_thickness",0.5,0,1.5)    -- thickness at start point
w1_r = ui_number("Weight_1",20,0,100)
alpha1_r = ui_number("Alpha_1",2,1,10)
p3_x_r = p3_x  -- Stop angle, be same as p3_x
p3_y_r = ui_number("Endpoint thickness",1,0,4)    -- Thickness at end point
w2_r = ui_number("Weight_2",10,5,15)
alpha2_r = ui_number("Alpha_2",10,5,15)

-- Parameters for casing
text = ui_number("Volute parameters",0,0,0)
r_outlet = ui_number("Outlet radius",7,5,10)
r_inlet = ui_number("Inlet radius",5,0,10)
r0_volute = ui_number("Volute radius",27,24,30)
alpha = 0.001 -- ui_scalar("Volute_alpha",0.001,0.000,0.002)
r_center = 20 -- ui_number("Volute center radius",20,15,25)
r_shaft = ui_number("Shaft radius",5,5,10)
casing_thickness =  ui_number("Volute thickness",1,1,3)
n_points_casing = 31 -- ui_number("Volute n_points",31,31,35)
n_points_fillet = 31 -- ui_number("Volute n_fillet",31,31,35)


function linspace(start,stop,n_points)
	-- return [n] = {start ... stop}
	local step = (stop-start)/(n_points-1)
	local ret = {}

	for n = 1,n_points do  
		ret[n] = start + step*(n-1)
	end

	return ret
end

function iniArr(row,col,val)
	local ret = {}

	for i = 1,row do  
		ret[i] = {}
		for j = 1,col do  
          ret[i][j] = val
		end
	end

	return ret
end


function ones(row,col)
	local ret = {}

	for i = 1,row do  
		ret[i] = {}
		for j = 1,col do  
          ret[i][j] = 1
		end
	end

	return ret
end

function zeros(row,col)
	local ret = {}

	for i= 1,row do  
		ret[i] = {}
		for j= 1,col do  
		ret[i][j] = 0
		end
	end

	return ret
end

function pol2cart(theta, r)
	-- theta in deg
	-- return [2][n=#theta] = {{X1 ... Xn},{Y1 ... Yn}}

	local XY = {}
	XY[1] = {}
	XY[2] = {}
	if (#theta == #r) then
		for n = 1,#theta do  		 	
			XY[1][n] = r[n]*math.cos(math.rad(theta[n]))--X
			XY[2][n] = r[n]*math.sin(math.rad(theta[n])) --Y
		end
	else
		print('Error at pol2cart(), theta and r are not same size')
	end
	
	return XY
end

function drawCircle3(r,pos,n_vector,start_angle,end_angle,n_points)
    
    --Gives the coordinates of the circle of radius "r" normal to the 
    -- vector "n_vector" with center at position "pos" from starting angle to ending angle in 3D space
    -- n_points is the number of support points between start and stop angle
    -- return [n_points] = {v(x1 y1 z1),...., v(xn yn zn)}
    --local x = {}
    --local y = {}
    --local z = {}
    local phi = math.atan2(n_vector[2],n_vector[1]) --Azimuth angle, between X and Y
    local theta = math.atan2(math.sqrt(n_vector[1]^2 + n_vector[2]^2),n_vector[3]) -- Zenith angle, between Z and XY
    
    -- Looping step size
    local t = linspace(start_angle,end_angle,n_points)
    
    local xyz = {}

    -- Calculate 3D coordinates of points on the circle
    for n=1,n_points do
    xyz[n] = v(
		--X
        pos[1]- r*(math.cos(t[n])*math.sin(phi) + math.sin(t[n])*math.cos(theta)*math.cos(phi) ),
        
        --Y
        pos[2]+ r*(math.cos(t[n])*math.cos(phi) - math.sin(t[n])*math.cos(theta)*math.sin(phi) ),
        
        --Z
        pos[3]+ r*math.sin(t[n])*math.sin(theta))

    end

    return xyz
end

function Bezier(p0_x,p0_y,w1,alpha1,p3_x,p3_y,w2,alpha2)
	-- alpha1 and alpha2 in deg
	-- fixed step t = 0.01
	-- X as theta and Y as R
	-- return [2][n] = {{X1 X2 ... Xn},{Y1 Y1 ... Yn}} with n=1/#t_step

    local XY= {}
    XY[1] = {}
    XY[2] = {}


    -- Calculate p1 and p2 base on weight and alpha
    local p1_x = p0_x + w1*math.cos(math.rad(alpha1))
	local p1_y = p0_y + w1*math.sin(math.rad(alpha1))
    local p2_x = p3_x - w2*math.cos(math.rad(alpha2))
	local p2_y = p3_y + w2*math.sin(math.rad(alpha2))

	local i = 1 -- looping counter

	-- Loop t = 0:0.01:1
	for t = 0,1.01,0.01 do

		--X
		XY[1][i] = p0_x*(  -(t^3) + 3*(t^2) - 3*t + 1)
				 + p1_x*( 3*(t^3) - 6*(t^2) + 3*t    )
				 + p2_x*(-3*(t^3) + 3*(t^2)          )
				 + p3_x*(   (t^3) 				 	 )

		--Y
		XY[2][i] = p0_y*(  -(t^3) + 3*(t^2) - 3*t + 1)
				 + p1_y*( 3*(t^3) - 6*(t^2) + 3*t    )
				 + p2_y*(-3*(t^3) + 3*(t^2)          )
				 + p3_y*(   (t^3) 				 	 )

		i = i + 1
	end

    return XY
end


function createImpeller(r_shroud, h_shroud, h_blade, centerline, blade_thickness)
--- Optional: Color input, add later if have time
--- Later: return error code

	-- Shroud
	local shroud = cylinder(r_shroud, h_shroud)
	emit(shroud)


	-- Impeller
	local blade_fraction = {}
	for i = 1,#centerline[1]-1 do
		local x1 = centerline[1][i]
		local y1 = centerline[2][i]
		local x2 = centerline[1][i+1]
		local y2 = centerline[2][i+1]

		local r1 = blade_thickness[2][i]
		local r2 = blade_thickness[2][i+1]


		local cyl_1 = translate(x1,y1,h_shroud)*cylinder(r1, h_blade)
		local cyl_2 = translate(x2,y2,h_shroud)*cylinder(r2, h_blade)

		blade_fraction[i] = convex_hull(union(cyl_1,cyl_2))

	end

	local blade = union(blade_fraction)
	emit(blade,7)

end

function createCasing(r_outlet, r_inlet, r0_volute, alpha, r_center, r_shaft, casing_thickness, n_points_casing, n_points_fillet)
	-- r_outlet/ r_inlet: radius of the outlet/inlet
	-- r0_volute, alpha: in the function r_volute(i) = r0_volute*exp(alpha*theta(i))
	-- r_inner: radius of the center hub
	-- casing_thickness: casing thickness
	-- n_points_casing: no of support points for the casing outer shape
	-- n_points_fillet: no of support points for the fillet of the casing

	local r_volute_outer = {}
	local r_volute_centerline = {}
	local theta = linspace(0,360,n_points_casing)
	local xy_volute_offset = {}


	-- Make the outer shell
	for i = 1, n_points_casing do
		r_volute_outer[i] = r0_volute*math.exp(alpha*theta[i])

		-- offset to the centerline so that the fillet lay on r_volute 
		r_volute_centerline[i] = r_volute_outer[i] - r_outlet
	end

    -- convert r_volute_offset to Cartesian, [2][i] = {{X...},{Y...}}
	xy_volute_centerline = pol2cart(theta,r_volute_centerline) 

	local xyz_volute_inner = {}
	local xyz_volute_outer = {}

	for i = 1, n_points_casing do
		-- normal vector
		local n_vect = {-math.sin(math.rad(theta[i])), math.cos(math.rad(theta[i])), 0}
		local center = {xy_volute_centerline[1][i], xy_volute_centerline[2][i], 0} -- local centerpoint
		
		xyz_volute_inner[i] = drawCircle3(r_outlet,center,n_vect,
								3/2*math.pi,math.pi/2,n_points_fillet)
		xyz_volute_outer[i] = drawCircle3(r_outlet+casing_thickness,center,n_vect,
								math.pi/2,3/2*math.pi,n_points_fillet)
		
	end


	-- Make the center hub
	-- Make array r_center to comply with the input type
	local r_center_arr = {}

	for i = 1, n_points_casing do
		r_center_arr[i] = r_center
	end

	xy_centerhub_line = pol2cart(theta,r_center_arr) 
	local xyz_center_inner = {}
	local xyz_center_outer = {}

	for i = 1, n_points_casing do
		local n_vect = {-math.sin(math.rad(theta[i])), math.cos(math.rad(theta[i])), 0}
		local center = {xy_centerhub_line[1][i], xy_centerhub_line[2][i], 0} -- local centerpoint

		xyz_center_inner[i] = drawCircle3(r_outlet,center,n_vect,
								math.pi/2,math.pi/4,n_points_fillet)
		xyz_center_outer[i] = drawCircle3(r_outlet+casing_thickness,center,n_vect,
								math.pi/4,math.pi/2,n_points_fillet)

	end


	-- Make the shaft hole
	-- Make array r_shaft to comply with the input type
	local r_shaft_arr = {}

	for i = 1, n_points_casing do
		r_shaft_arr[i] = r_shaft
	end

	xy_shaft_line = pol2cart(theta,r_shaft_arr) 
	local xyz_shaft_inner = {}
	local xyz_shaft_outer = {}

	for i = 1, n_points_casing do
		xyz_shaft_inner[i] = v(xy_shaft_line[1][i],
							   xy_shaft_line[2][i],
							   -r_outlet)
		xyz_shaft_outer[i] = v(xy_shaft_line[1][i],
							   xy_shaft_line[2][i],
							   -r_outlet-casing_thickness)

	end


	-- Make the inlet (eye)
	-- Make array r_inlet to comply with the input type
	local r_inlet_arr = {}

	for i = 1, n_points_casing do
		r_inlet_arr[i] = r_inlet
	end

	xy_inlet_line = pol2cart(theta,r_inlet_arr) 
	local xyz_inlet_inner = {}
	local xyz_inlet_outer = {}

	for i = 1, n_points_casing do
		xyz_inlet_inner[i] = v(xy_inlet_line[1][i],
							   xy_inlet_line[2][i],
							   xyz_center_inner[i][n_points_fillet].z)
		xyz_inlet_outer[i] = v(xy_inlet_line[1][i],
							   xy_inlet_line[2][i],
							   xyz_center_outer[i][1].z)

	end

	-- Make final contour by connecting all the contours
	local xyz_volute_contour = {}
	xy_shaft_line = pol2cart(theta,r_center_arr) 


	for i = 1,n_points_casing do
		xyz_volute_contour[i] = {}

		-- Outer line of the center hub
		for j = 1,#xyz_center_outer do
			xyz_volute_contour[i][(#xyz_volute_contour[i])+1] = xyz_center_outer[i][j]
		end

		-- Outer line of the volute shell
		for j = 1,#xyz_volute_outer do
			xyz_volute_contour[i][(#xyz_volute_contour[i])+1] = xyz_volute_outer[i][j]
		end

		-- Outer line of the shaft hole
		xyz_volute_contour[i][(#xyz_volute_contour[i])+1] = xyz_shaft_outer[i]

		-- Inner line of the shaft hole
		xyz_volute_contour[i][(#xyz_volute_contour[i])+1] = xyz_shaft_inner[i]

		-- Inner line of the volute shell
		for j = 1,#xyz_volute_inner do
			xyz_volute_contour[i][(#xyz_volute_contour[i])+1] = xyz_volute_inner[i][j]
		end

		-- Inner line of the center hub
		for j = 1,#xyz_center_inner do
			xyz_volute_contour[i][(#xyz_volute_contour[i])+1] = xyz_center_inner[i][j]
		end

		-- Inner line of the inlet
		xyz_volute_contour[i][(#xyz_volute_contour[i])+1] = xyz_inlet_inner[i]

		-- Outer line of the inlet
		xyz_volute_contour[i][(#xyz_volute_contour[i])+1] = xyz_inlet_outer[i]

	end

	display = translate(0,0,r_outlet/2)*sections_extrude(xyz_volute_contour)

    -- Create a cut object to show the model
	cut = translate(-25,-25,-20)*cube(50,50,50)


	emit(difference(display,cut),5)
end




-------------------------------------------------------------------
-- Main part to create the model

--Impeller
center_line_polar = Bezier(p0_x,p0_y,w1,alpha1,p3_x,p3_y,w2,alpha2)
center_line_cart = pol2cart(center_line_polar[1], center_line_polar[2])

blade_thickness_polar = Bezier(p0_x_r,p0_y_r,w1_r,alpha1_r,p3_x_r,p3_y_r,w2_r,alpha2_r)

if(view==1) then
createImpeller(r_shroud,h_shroud,h_blade,center_line_cart,blade_thickness_polar)
end

if(view==2) then
-- Casing
createCasing(r_outlet, r_inlet, r0_volute, alpha, r_center, r_shaft, casing_thickness, n_points_casing, n_points_fillet)
end

if(view==0) then
	createImpeller(r_shroud,h_shroud,h_blade,center_line_cart,blade_thickness_polar)
	createCasing(r_outlet, r_inlet, r0_volute, alpha, r_center, r_shaft, casing_thickness, n_points_casing, n_points_fillet)
end