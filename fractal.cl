#ifndef DEBUG
#define DEBUG 0
#endif

#ifndef NUMBER_OF_ITERATIONS
#define NUMBER_OF_ITERATIONS 1024
#endif

#ifndef FRAC_EXPRESSION
#define FRAC_EXPRESSION cadd(cmul(z,z), c)
#endif

#ifndef FRACTAL_FUNC
#define FRACTAL_FUNC mandelbrot
#endif


double2 cadd(const double2 a, const double2 b) { return (double2)(a.x + b.x, a.y + b.y); }
double2 csub(const double2 a, const double2 b) { return (double2)(a.x - b.x, a.y - b.y); }
double2 cmul(const double2 a, const double2 b) { return (double2)(a.x*b.x - a.y*b.y, a.y*b.x + a.x*b.y); }
double  cmag2(const double2 a) { return a.x * a.x + a.y * a.y; }
double2 cdiv(const double2 a, double2 b) {
	const double denom = cmag2(b);
	return (double2)((a.x*b.x + a.y*b.y)/denom, (a.y*b.x + a.x*b.y)/denom);
}

double fractal(const double2 c, const double2 z_) {
	double2 z = z_;
	for (int iteration = 0; iteration < NUMBER_OF_ITERATIONS; iteration++) {
		z = FRAC_EXPRESSION;
		if (cmag2(z) > NUMBER_OF_ITERATIONS) {
			double sl = iteration - log2(log2(z.x * z.x + z.y * z.y)) + 4.0;
			return sl;
		}
	}
	return 0.0;
}

double mandelbrot(const double2 coordinate,const double2 offset) {
	double2 c = (double2)(coordinate.x, coordinate.y);
	double2 z = (double2)(0.0, 0.0);

	return fractal(c, z);
}

double julia(const double2 coordinate, const double2 offset) {
	double2 c = (double2)(offset.x, offset.y);
	double2 z = (double2)(coordinate.x, coordinate.y);

	return fractal(c, z);
}

kernel void sum(
	double r_min,
	double i_min,
	double r_step,
	double i_step,
	global uchar *outbuf
) {
	private double r;
	private double i;
	private size_t idx;
	private double fractalValue;
	private double3 color;
	private uchar3 color_byte;
	//double aspect_rato = ((double) get_global_size(0)) / ((double) get_global_size(1));
	//double2 center = (double2) (-0.743643887037151, 0.131825904205330);

	r = r_min + r_step * convert_double(get_global_id(0));
	i = i_min + i_step * convert_double(get_global_id(1));

	idx = (get_global_id(1) * get_global_size(0) + get_global_id(0)) * 3;
	fractalValue = FRACTAL_FUNC((double2)(r, i), (double2)(0, 0));
	color = 0.5 + 0.5*cos( 3.0 + fractalValue*0.15 + (double3)(0.0,0.6,1.0));
	color_byte = convert_uchar3(color*256);

	outbuf[idx+0] = convert_uchar(color_byte.x);
	outbuf[idx+1] = convert_uchar(color_byte.y);
	outbuf[idx+2] = convert_uchar(color_byte.z);

#if DEBUG
	printf("%6llu %6llu | %6llu | %9f %9f %9f %9f | %9f %9f | %9f \n",
		(size_t) get_global_id(0),
		(size_t) get_global_id(1),
		(size_t) idx,
		(double) r_min,
		(double) i_min,
		(double) r_step,
		(double) i_step,
		(double) r,
		(double) i,
		(double) fractalValue
		);
#endif
}
