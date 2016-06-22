@doc """
	voronoiarea(x::Vector, y::Vector; rw) -> Vector

Compute the area of each Voronoi cell in the tesselation generated by `x` and `y`.

The vector `rw` specifies the boundary rectangle as `[xmin, xmax, ymin, ymax]`.
By default, `rw` is the unit rectangle.
"""->
function voronoiarea(x::Vector{Float64}, y::Vector{Float64}; rw::Vector{Float64}=[0.0;1.0;0.0;1.0])
	pts, SCALEX, SCALEY = fit2boundingbox(x, y, rw)

	# Areas for scaled points
	C = vcorners(pts)
	A = voronoiarea(C)

	scale!(A, SCALEX*SCALEY)

	return A
end

@doc """
	voronoiarea(C::Tessellation) -> Vector

Compute the area of each of the Voronoi cells in `C`.

Note that if the polygons of `C` are not ordered, they will be changed in-place.
"""->
function voronoiarea(C::Tessellation)
	NC = length(C)
	A = Array{Float64}(NC)

	for n in 1:NC
		A[n] = polyarea( C[n] )
	end

	return A
end

@doc """
	polyarea(p::AbstractPoints2D)

Compute the area of the polygon with vertices `p` using the shoelace formula.  
If the points in `p` are not sorted, they will be sorted **in-place**.
"""->
function polyarea{T<:AbstractPoint2D}(pts::Vector{T})
	# TODO: Append ! to function name
	issorted(pts) || sort!(pts)

	Np = length(pts)
	A = getx(pts[1])*( gety(pts[2]) - gety(pts[Np]) ) + getx(pts[Np])*( gety(pts[1]) - gety(pts[Np-1]) )

	for n in 2:Np-1
		A += getx(pts[n])*( gety(pts[n+1]) - gety(pts[n-1]) )
	end

	return 0.5*abs(A)
end

# Compute the average point of pts
function Base.mean{T<:AbstractPoint2D}(pts::Vector{T})
	# Average point
	ax = 0.0
	ay = 0.0

	for p in pts
		ax += getx(p)
		ay += gety(p)
	end

	Np = length(pts)
	Point2D(ax/Np, ay/Np)
end

# TODO: Input is AbstractPoint2D, but output is Point2D. Is AbstractPoint2D necessary?
# Addition and subtraction for AbstractPoint2D
for op in [:+,:-]
	@eval begin
		Base.$op(p::AbstractPoint2D, q::AbstractPoint2D) = Point2D( $op(getx(p), getx(q)), $op(gety(p), gety(q)) )
	end
end

function Base.(:*)(a::Float64, p::AbstractPoint2D)
	Point2D( a*getx(p), a*gety(p) )
end

# sorting for AbstractPoints2D
for name in [:sort!,:issorted]
	@eval begin
		function Base.$name{T<:AbstractPoint2D}(pts::Vector{T})
			center = mean(pts)
			centralize = p -> p - center
			$name( pts, by=centralize )
		end
	end
end

# http://stackoverflow.com/questions/6989100/sort-points-in-clockwise-order
function Base.isless(p::AbstractPoint2D, q::AbstractPoint2D)
	if getx(p) >= 0.0 && getx(q) < 0.0
		return true
	elseif getx(p) < 0.0 && getx(q) >= 0.0
		return false
	elseif getx(p) == getx(q) == 0.0
		if gety(p) >= 0.0 || gety(q) >= 0.0
			return gety(p) > gety(q)
		else
			return gety(p) < gety(q)
		end
	end

	det = getx(p)*gety(q) - getx(q)*gety(p)
	if det < 0.0
		return true
	elseif det > 0.0
		return false
	end

	# p and q are on the same line from the center; check which one is
	# closer to the origin
	origin = Point2D(0.0, 0.0)
	dist_squared(p,origin) > dist_squared(q,origin)
end

