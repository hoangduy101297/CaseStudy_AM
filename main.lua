-- Parameters for shroud
r_shroud = 22
h_shroud = 2
h_blade = 7

-- Bezier control point for centerline
p0_x = 0      -- Start angle
p0_y = 5      -- Start radius
w1 = 20
alpha1 = 15
p3_x = 330    -- Wrap angle
p3_y = 20     -- 
w2 = 50
alpha2 = -10

-- Bezier control point for blade thickness
p0_x_r = 0     -- Start angle
p0_y_r = 0.5     -- thickness at start point
w1_r = 20
alpha1_r = 2
p3_x_r = p3_x  -- Stop angle, be same as p3_x
p3_y_r = 1    -- Thickness at end point
w2_r = 10
alpha2_r = 10


function linspace(start,stop,n_points)
	-- return [n] = {start ... stop}
	local step = (stop-start)/(n_points-1)
	local ret = {}

	for n = 1,n_points do  
		ret[n] = start + step*(n-1)
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
    -- return [3][n_points] = {{X1 ... Xn},{Y1 ... Yn},{Z1 ... Zn}}
    local x = {}
    local y = {}
    local z = {}
    phi = math.atan2(n_vector[2],n_vector[1]) --Azimuth angle, between X and Y
    theta = math.atan2(math.sqrt(n_vector[1]^2 + n_vector[2]^2),n_vector[3]) -- Zenith angle, between Z and XY
    
    -- Looping step size
    t = linspace(start_angle,end_angle,n_points)
    
    -- Calculate 3D coordinates of points on the circle
    for n=1,n_points do

		--X
        x[n]= pos[1]- r*(math.cos(t[n])*math.sin(phi) + math.sin(t[n])*math.cos(theta)*math.cos(phi) )
        
        --Y
        y[n]= pos[2]+ r*(math.cos(t[n])*math.cos(phi) - math.sin(t[n])*math.cos(theta)*math.sin(phi) )
        
        --Z
        z[n]= pos[3]+ r*math.sin(t[n])*math.sin(theta)
    end
    local xyz = {x,y,z}
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

	-- Don't know why loop stops at 0.99, not 1
	for t = 0,1,0.01 do

		--X
		XY[1][i] = p0_x*(  -(t^3) + 3*(t^2) - 3*t + 1)
				 + p1_x*( 3*(t^3) - 6*(t^2) + 3*t    )
				 + p2_x*(-3*(t^3) + 3*(t^2)          )
				 + p3_x*(   (t^3) 				 )

		--Y
		XY[2][i] = p0_y*(  -(t^3) + 3*(t^2) - 3*t + 1)
				 + p1_y*( 3*(t^3) - 6*(t^2) + 3*t    )
				 + p2_y*(-3*(t^3) + 3*(t^2)          )
				 + p3_y*(   (t^3) 				 )

		i = i + 1;
	end

	-- So manually calculate t = 1 as a workaround
	t = 1
	XY[1][101] = p0_x*(  -t^3 + 3*t^2 - 3*t + 1)
			 + p1_x*( 3*t^3 - 6*t^2 + 3*t    )
			 + p2_x*(-3*t^3 + 3*t^2          )
			 + p3_x*(   t^3 				 )

	--Y
	XY[2][101] = p0_y*(  -t^3 + 3*t^2 - 3*t + 1)
			   + p1_y*( 3*t^3 - 6*t^2 + 3*t    )
			   + p2_y*(-3*t^3 + 3*t^2          )
			   + p3_y*(   t^3 				 )

    return XY
end


function createImpeller(r_shroud, h_shroud, h_blade, centerline, blade_thickness)
--- Optional: Color input, add later if have time
--- Later: return error code

	-- Shroud
	local shroud = cylinder(r_shroud, h_shroud)
	emit(shroud)
	local blade_fraction = {}
	-- Impeller
	for i = 1,#centerline[1]-1 do
		local x1 = centerline[1][i]
		local y1 = centerline[2][i]
		local x2 = centerline[1][i+1]
		local y2 = centerline[2][i+1]

		local r1 = blade_thickness[2][i]
		local r2 = blade_thickness[2][i+1]


		cyl_1 = translate(x1,y1,h_shroud)*cylinder(r1, h_blade)
		cyl_2 = translate(x2,y2,h_shroud)*cylinder(r2, h_blade)

		blade_fraction[i] = convex_hull(union(cyl_1,cyl_2))

	end

	blade = union(blade_fraction)
	emit(blade,7)

end



center_line_polar = Bezier(p0_x,p0_y,w1,alpha1,p3_x,p3_y,w2,alpha2)
center_line_cart = pol2cart(center_line_polar[1], center_line_polar[2])

blade_thickness_polar = Bezier(p0_x_r,p0_y_r,w1_r,alpha1_r,p3_x_r,p3_y_r,w2_r,alpha2_r)


createImpeller(r_shroud,h_shroud,h_blade,center_line_cart,blade_thickness_polar)