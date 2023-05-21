-----------------------------------------------------------------
-- Case Study Cyper Physical Production Systems using AM (SS2023)
--
--  Under guidance of: Prof. Dr. Ing. Stefan Scherbarth
----------------------------------------------------------------
--  Group 11: Centrifugal Pump with Semi-open Single Vane Impeller
--  Members:
--   Tran Hoang Duy Nguyen   	- 22203230
--   Thushar Tom   				- 22202815
--   Sreehari Giridharan   		- 22200251
--   Alla Durga Nooka Venkatesh - 22207330
--
--  Last Update: 21.05.2023
----------------------------------------------------------------


view_list = {
	{0, "Full view"},
	{1, "Impeller"},
	{2, "Volute"}
}

view = ui_radio("View:",view_list)
casing_cut = ui_bool("View cut through",false)

-- Global scale
global_scale = ui_scalar("Global scale",1,0.5,2)

-- Parameters for shroud

spline_shroud_gap = 2
r_shroud = ui_scalar("Shroud radius [mm]",25,20,40)
h_shroud = ui_scalar("Shroud thickness [mm]",1,1,2)
h_blade = ui_scalar("Blade height [mm]",r_shroud/4,3,r_shroud/3)
impeller_spinning = ui_numberBox("Impeller spinning",1)
-- r_outlet from r_shroud/5 to r_shroud/3
-- casing_gap = ui_scalar("Gap between impeller and housing [mm]",3,2,4)

r_shaft = ui_scalar("Shaft radius [mm]",3,1,r_shroud/4)

-- Bezier control point for blade centerline
impeller_centerline_list = {
	{0, "Bézier curve"},
}
impeller_centerline_method=ui_radio("Impeller blade centerline design method:",impeller_centerline_list)

p0_x_cl = ui_number("Start-point angle [°]",0,0,90)      -- Start angle
p0_y_cl = ui_scalar("Start-point radius [mm]",5,2.785,r_shroud*0.4)     -- Start radius
w1_cl = ui_number("Weight 1",10,0,30)
alpha1_cl = ui_number("Alpha 1 [°]",10,-15,15)
p3_x_cl = ui_number("End-point angle\n(Blade wrap angle) [°]",300,250,360)    -- Wrap angle
p3_y_cl = ui_scalar("End-point radius [mm]",r_shroud*0.8,r_shroud*0.7,r_shroud-(r_shroud/10))     -- 
w2_cl = ui_number("Weight 2",10,0,30)
alpha2_cl = ui_number("Alpha 2 [°]",-10,-15,15)


-- Bezier control point for blade thickness
impeller_thickness_list = {
	{0, "Bézier curve "},
}
impeller_thickness_method=ui_radio("Impeller blade thickness design method:",impeller_thickness_list)

p0_x_t = ui_number("Start-point angle [°]\n(inherit from centerline)",p0_x_cl,p0_x_cl,p0_x_cl)     -- Start angle
p0_y_t = ui_scalar("Start-point thickness [mm]",1.5,1,r_shroud/10)    -- thickness at start point
w1_t = ui_number("Weight 1 ",5,3,7)
alpha1_t = ui_number("Alpha 1 [°] ",0,-6,15)
p3_x_t = ui_number("End-point angle [°]\n(inherit from centerline)",p3_x_cl,p3_x_cl,p3_x_cl)
p3_y_t = ui_scalar("End-point thickness [mm]",1.5,1,r_shroud/10)    -- Thickness at end point
w2_t = ui_number("Weight 2 ",5,3,7)
alpha2_t = ui_number("Alpha 2 [°] ",0,-6,15)


-- Parameters for casing
casing_list = {
	{0, "Bézier curve  "},
	{1, "Logarithm  "},
}

casing_method = ui_radio("Volute design method:",casing_list)
casing_thickness =  ui_scalar("Volute thickness [mm]",1,1,3)
--r_outlet = ui_scalar("Outlet radius [mm]",r_shroud/4,r_shroud/5,r_shroud/3)
r_outlet = ui_scalar("Outlet radius [mm]",(h_shroud+h_blade+2)*0.7,(h_shroud+h_blade+2)/2,(h_shroud+h_blade+2))
r_inlet = ui_scalar("Inlet radius [mm]",r_shroud/5,1,r_shroud/4)

if (casing_method == 0) then
	p0_x_vl = ui_number("Start-point angle [°]\n(fixed as 180°)",180,180,180)     -- Start angle
	p0_y_vl = ui_scalar("Start-point volute radius [mm]",r_shroud*1.2,r_shroud*1.2,r_shroud*1.5)    -- thickness at start point
	w1_vl = ui_number("Weight 1  ",3,0,10)
	alpha1_vl = ui_number("Alpha 1  [°] ",0,-15,15)
	p3_x_vl = ui_number("End-point angle [°]\n(fixed as -180°)",-180,-180,-180)
	p3_y_vl = ui_scalar("End-point volute radius [mm]",r_shroud*1.5,p0_y_vl,r_shroud*1.8)    -- Thickness at end point
	w2_vl = ui_number("Weight 2  ",3,0,10)
	alpha2_vl = ui_number("Alpha 2  [°]",0,-15,15)

elseif (casing_method == 1) then
	r0_volute = ui_scalar("Volute starting radius [mm]",r_shroud*1.2,r_shroud*1.2,r_shroud*1.5)
	alpha = ui_number("Alpha ",5,5,12)
	alpha = alpha*0.0001
end

-- Internal control params
n_points_casing 	= 51
n_points_fillet 	= 51


--------------------------------------------------
function linspace(start,stop,n_points)
	-- To create a linear spacing between start and stop points, with n_points support points
	-- return array[n] = {start ... stop}
	local step = (stop-start)/(n_points-1)
	local ret = {}

	for n = 1,n_points do  
		ret[n] = start + step*(n-1)
	end

	return ret
end

function pol2cart(theta, r)
	-- To convert Polar coordinates to Cartesian Coordinate
	-- theta in deg
	-- param: theta = {}, r = {} with same size [n]
	-- return array[2][n] = {{X1 ... Xn},{Y1 ... Yn}}

	local XY = {}
	XY[1] = {}
	XY[2] = {}
	if (#theta == #r) then
		for n = 1,#theta do  		 	
			XY[1][n] = r[n]*math.cos(math.rad(theta[n]))--X
			XY[2][n] = r[n]*math.sin(math.rad(theta[n])) --Y
		end
	else
		print('Internal error at pol2cart(), theta and r are not same size')
	end
	
	return XY
end

function drawCircle3(r,pos,n_vector,start_angle,end_angle,n_points)
    --To compute the coordinates for the circle of radius "r" normal to the 
    -- vector "n_vector" with center at position "pos" from starting angle to ending angle in 3D space
    -- n_points is the number of support points between start and stop angle (in rad)
    -- return array[n_points] = {v(x1 y1 z1),...., v(xn yn zn)}

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
	-- To compute the set of coordinates for the Beziert curve with 4 control points
	-- 4 control points are represented in form of 2 start/end points and 2 weights/angles
	-- alpha1 and alpha2 in deg
	-- fixed step t = 0.02
	-- return array[2][n] = {{X1 X2 ... Xn},{Y1 Y1 ... Yn}} with n=51 (t = 0.02)

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
	for t = 0,1.01,0.02 do
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


function createImpeller()
	-- Create impeller, required parameters are declared globally
	-- function also checks for related geometrical constraints

	-- Shroud
	local shroud = cylinder(r_shroud + spline_shroud_gap, h_shroud)
	local shaft_key = union(cylinder(r_shaft, h_shroud),
				translate(0,r_shaft,0)*cube(r_shaft/2,r_shaft/2,h_shroud))
	emit(scale(global_scale)*rotate(0,0,impeller_spinning*360/100)*difference(shroud,shaft_key))
	emit(scale(global_scale)*rotate(0,0,impeller_spinning*360/100)*shaft_key,3)

	-- Blade
	local center_line_polar = Bezier(p0_x_cl,p0_y_cl,w1_cl,alpha1_cl,p3_x_cl,p3_y_cl,w2_cl,alpha2_cl)
	local center_line_cart = pol2cart(center_line_polar[1], center_line_polar[2])
	
	local blade_thickness = Bezier(p0_x_t,p0_y_t,w1_t,alpha1_t,p3_x_t,p3_y_t,w2_t,alpha2_t)

	local blade_r_plus = {}
	local blade_r_minus = {}

	local error_msg = ""

	for i = 1,#center_line_cart[1] do
		if(center_line_polar[2][i]+blade_thickness[2][i] > r_shroud) then
			error_msg = "Error! The impeller blade hits the shroud border. \n -> Please adjust Bézier parameters.\n"
		end

		if(blade_thickness[2][i] <= 0) then
			error_msg = "Error! The impeller blade thickness goes below zero. \n -> Please adjust Bézier parameters.\n"
		end

		-- Create 2 offset from the centerline, with distance as blade thickness
		local xy_r_plus = pol2cart({center_line_polar[1][i]}, {center_line_polar[2][i]+blade_thickness[2][i]})
		local xy_r_minus = pol2cart({center_line_polar[1][i]}, {center_line_polar[2][i]-blade_thickness[2][i]})
		table.insert(blade_r_plus,v(xy_r_plus[1][1],xy_r_plus[2][1],0))
		table.insert(blade_r_minus,v(xy_r_minus[1][1],xy_r_minus[2][1],0))


	end

	-- Concatenate to make full blade contour
	for i = #blade_r_minus, 1,-1 do
		table.insert(blade_r_plus,blade_r_minus[i])
	end

	-- Finally add half-circles at 2 ends
	local cir1 = translate(center_line_cart[1][1],center_line_cart[2][1],0)*cylinder(blade_thickness[2][1]-0.05,h_blade+h_shroud)
	local cir2 = translate(center_line_cart[1][#center_line_cart[1]],center_line_cart[2][#center_line_cart[1]],0)*cylinder(blade_thickness[2][#blade_thickness[1]]-0.05,h_blade+h_shroud)
	local blade = union{linear_extrude(v(0,0,h_blade+h_shroud),blade_r_plus),cir1,cir2}

	print(error_msg)

	-- Add shroud border (not visible), just to make sure the model is displayed as intended
	local shroud_border = cylinder(r_shroud, h_shroud+h_blade)
	blade = intersection(blade,shroud_border)

	emit(scale(global_scale)*rotate(0,0,impeller_spinning*360/100)*blade,7)

end

function createCasing()
	-- Create volute casing, required parameters are declared globally
	-- function also checks for related geometrical constraints

	local theta = linspace(180,-180,n_points_casing)

	local xy_volute_centerline = {}
	local r_volute_outer = {}
	local r_volute_centerline = {}
	local error_msg = "" 

	if (casing_method == 0) then 
		-- Make the volute from Bezier curve
		r_volute_outer = Bezier(p0_x_vl,p0_y_vl,w1_vl,alpha1_vl,p3_x_vl,p3_y_vl,w2_vl,alpha2_vl)
		
		for i = 1, #r_volute_outer[1] do
			
			-- offset to the centerline so that the fillet lay on r_volute 
			r_volute_centerline[i] = r_volute_outer[2][i] - r_outlet 
			
			-- Check if the shroud hits the volute, geometrically proven
			if (r_shroud > r_volute_centerline[i]) then
				if( math.sqrt((r_shroud-r_volute_centerline[i])^2 +((h_shroud+h_blade)*0.5)^2) >= r_outlet ) then
					error_msg = "Error! The impeller shroud hits the volute. \n -> Please either increase volute starting radius or decrease impeller shroud radius\n"
				end
			end

		end
		print(error_msg)

		xy_volute_centerline = pol2cart(r_volute_outer[1], r_volute_centerline)
	elseif (casing_method == 1) then
		-- Make the volute from logarithm function
		for i = 1, n_points_casing do
			r_volute_outer[i] = r0_volute*math.exp(alpha*(180-theta[i]))

			-- offset to the centerline so that the fillet lay on r_volute_outer 
			r_volute_centerline[i] = r_volute_outer[i] - r_outlet

			-- Dont need to check if the shroud hits the volute, because radius always increases due to logarithm function
		end

	    -- convert r_volute_offset to Cartesian, [2][i] = {{X...},{Y...}}
		xy_volute_centerline = pol2cart(theta,r_volute_centerline) 
	end

	local xyz_volute_inner = {}
	local xyz_volute_outer = {}

	-- Draw circle contours in 3D, later use sections_extrude to connect them
	for i = 1, n_points_casing do
		-- normal vector
		local n_vect = {-math.sin(math.rad(theta[i])), math.cos(math.rad(theta[i])), 0}
		local center = {xy_volute_centerline[1][i], xy_volute_centerline[2][i], 0} -- local centerpoint
		
		-- Original outlet radius
		xyz_volute_inner[i] = drawCircle3(r_outlet,center,n_vect,
								3/2*math.pi,math.pi/2,n_points_fillet)
		-- Add 2 more points in the center, to create a solid body starting from the center
		table.insert(xyz_volute_inner[i],v(0,0,r_outlet))
		table.insert(xyz_volute_inner[i],v(0,0,-r_outlet))


		-- Outer shell adding the thickness
		xyz_volute_outer[i] = drawCircle3(r_outlet+casing_thickness,center,n_vect,
								3/2*math.pi,math.pi/2,n_points_fillet)
		-- Add 2 more points in the center, to create a solid body starting from the center
		table.insert(xyz_volute_outer[i],v(0,0,r_outlet+casing_thickness))
		table.insert(xyz_volute_outer[i],v(0,0,-r_outlet-casing_thickness))
	end

	local volute_outer = sections_extrude(xyz_volute_outer)
	local volute_inner = sections_extrude(xyz_volute_inner)
	local volute_main_part = difference(volute_outer,volute_inner)

	--------------------------------------------
	----------- Make the outlet ----------------
	local outlet_outer = translate(-r_volute_centerline[#r_volute_centerline],0,0)*rotate(-90,0,0)*cylinder(r_outlet+casing_thickness,r_volute_centerline[1]*1.2)
	local outlet_end = translate(-r_volute_centerline[#r_volute_centerline],r_volute_centerline[1]*1.2,0)*rotate(-90,0,0)*cylinder(1.5*(r_outlet+casing_thickness),3)
	local outlet_inner = translate(-r_volute_centerline[#r_volute_centerline],0,0)*rotate(-90,0,0)*cylinder(r_outlet,r_volute_centerline[1]*1.2+3)
	local outlet = difference(union(outlet_outer,outlet_end),outlet_inner)

	-- Matching the outlet with the volute
	local part1 = difference(volute_main_part,outlet_inner)

	local part2 = difference(outlet,volute_inner)

	local volute_with_outlet = union(part1,part2)

	--------------------------------------------
	-- Make the shaft hole
	local shaft_hole = translate(0,0,-casing_thickness-r_outlet)*cylinder(r_shaft*1.2,casing_thickness)

	--------------------------------------------
	-- Make the inlet
	local inlet_inner = translate(0,0,r_outlet)*cylinder(r_inlet,8+casing_thickness)
	local inlet_outer = translate(0,0,r_outlet+casing_thickness)*cylinder(r_inlet+casing_thickness,5)
	local inlet_end = translate(0,0,r_outlet+casing_thickness+5)*cylinder((r_inlet+casing_thickness)*1.5,3)
	local inlet = difference(union(inlet_end,inlet_outer),inlet_inner)

	--------------------------------------------
	---- Make a plate to fill the gap
	---- between volute and outlet -------------
	local closing_plate_contour = xyz_volute_outer[#xyz_volute_outer]

	local closing_plate = linear_extrude(v(0,1,0),closing_plate_contour)
	closing_plate = difference{closing_plate,volute_inner,outlet_inner,shaft_hole,inlet_inner}


	--------------------------------------------
	-- Make final object
	local final_volute = union{difference{volute_with_outlet,inlet_inner,shaft_hole},
						 closing_plate,
						 inlet}

	-- translate the casing so that the impeller is aligned at the middle of the casing space
	-- Calculation z = (2*r-h_shroud_h_blade)/2)
	final_volute = translate(0,0,0.5*(h_shroud+h_blade))*final_volute


	--------------------------------------------
    -- Create a cut object to show the model
	local cut = translate(-75*global_scale,0,0.5*(h_shroud+h_blade))*scale(global_scale)*cube(150,150,100)

	if(casing_cut == false) then
		emit(scale(global_scale)*final_volute,5)
	else
		emit(scale(global_scale)*difference(final_volute,cut),5)
	end

end

-------------------------------------------------------------------
-- Main part to create the model

-- Check if the volute is high enough
if( h_shroud + h_blade >= 2*r_outlet) then
	print("Error! The impeller height is larger than the volute space. \n -> Please either increase outlet radius or decrease impeller shroud height/ blade height\n")
end

-- Emit depending on chosen view
if(view == 0) then
	-- Full view
	createImpeller()
	createCasing()
elseif (view == 1) then
	--Impeller
	createImpeller()
elseif (view == 2) then
	-- Casing
	createCasing()	
end