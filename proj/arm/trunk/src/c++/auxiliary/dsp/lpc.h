#ifndef DSP_LPC_H
#define DSP_LPC_H

#include <algorithm>
#include <functional>
#include <numeric>
#include <vector>
#include <cmath>
#include <stdexcept>
#include <string>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace dsp {

	/************************************************************************/
	/* Linear prediction filter coefficients                                */
	/************************************************************************/
	// Levinson-Durbin recursion.
	template<typename _data_internal_t_>
	bool levinson(	const std::vector<_data_internal_t_> & R,
					std::vector<_data_internal_t_> *a_out=NULL,
					std::vector<_data_internal_t_> *rc_out=NULL,
					_data_internal_t_ *err_power=NULL) {
		size_t order=R.size()-1;

		const size_t max_stack_order=36;
		_data_internal_t_ a_tmp_stack[max_stack_order+1], rc_tmp_stack[max_stack_order];
		std::vector<_data_internal_t_> a_tmp_vec, rc_tmp_vec;
		_data_internal_t_ *a, *rc;

		if(a_out) {
			a_out->resize(order+1);
			a=&(*a_out)[0];
			a[0]=(_data_internal_t_)1;
		}
		else {
			if(order<=max_stack_order)
				a=a_tmp_stack;
			else {
				a_tmp_vec.resize(order+1);
				a=&a_tmp_vec[0];
			}
		}

		if(rc_out) {
			rc_out->resize(order);
			rc=&(*rc_out)[0];
		}
		else {
			if(order<=max_stack_order)
				rc=rc_tmp_stack;
			else {
				rc_tmp_vec.resize(order);
				rc=&rc_tmp_vec[0];
			}
		}

		if(R[0]) {
			rc[0] = -R[1]/R[0];
			a[1] = rc[0];
		}
		else
			rc[0]=1;

		if(rc[0]!=rc[0] || fabs(rc[0]) > (_data_internal_t_)0.999451) {	// Test for unstable filter.
			if(a_out)
				std::fill(a_out->begin()+1, a_out->end(), (_data_internal_t_)0);
			if(rc_out)
				std::fill(rc_out->begin(), rc_out->end(), (_data_internal_t_)0);
			if(err_power)
				*err_power=(_data_internal_t_)0;
			return false;
		}

		_data_internal_t_ err = R[0] + R[1]*rc[0];

		for (size_t i=2; i<=order; ++i) {

			_data_internal_t_ s = (_data_internal_t_)0;
			for (size_t j=0; j<i; ++j)
				s += R[i-j]*a[j];

			if(err != (_data_internal_t_)0)
				rc[i-1]=(-s)/(err);
			else
				rc[i-1]=(_data_internal_t_)1;

			if(rc[i-1]!=rc[i-1] || fabs(rc[i-1]) > (_data_internal_t_)0.999451) {	// Test for unstable filter.
				if(a_out)
					std::fill(a_out->begin()+1, a_out->end(), (_data_internal_t_)0);
				if(rc_out)
					std::fill(rc_out->begin(), rc_out->end(), (_data_internal_t_)0);
				if(err_power)
					*err_power=(_data_internal_t_)0;
				return false;
			}

			for(size_t j=1; j<=(i/2); ++j) {
				size_t l = i-j;
				_data_internal_t_ at = a[j] + rc[i-1]*a[l];
				a[l] += rc[i-1]*a[j];
				a[j] = at;
			}
			a[i] = rc[i-1];
			err += rc[i-1]*s;
			if (err<=(_data_internal_t_)0.0)
				err=(_data_internal_t_)0.001;
		}

		if(err_power)
			*err_power=err;

		return true;
	}

	// Computes the autocorrelation function of small order. For higher orders see xcorr
	template<typename _data_internal_t_, typename _DataIt>
	std::vector<_data_internal_t_> autocorr(_DataIt x_beg, _DataIt x_end, size_t order) {
		std::vector<_data_internal_t_> R(order + 1);
		for(size_t i=0; i<=order; ++i)
			R[i]=std::inner_product(x_beg+i, x_end, x_beg, (_data_internal_t_)0);
		std::transform(R.begin(), R.end(), R.begin(), std::bind2nd(std::divides<_data_internal_t_>(), x_end-x_beg) );
		return R;
	}

	template<typename _DataIt>
	bool lpc(	_DataIt x_beg, _DataIt x_end, size_t order,
		std::vector<double> *a_out=NULL,
		std::vector<double> *rc_out=NULL,
		double *err_power=NULL) {
			return levinson(autocorr<double>(x_beg, x_end, order), a_out, rc_out, err_power);
	}

	// Linear Predictive Coefficients using autocorrelation method.
	template<typename _DataIt>
	bool lpc(	_DataIt x_beg, _DataIt x_end, size_t order,
				std::vector<float> *a_out=NULL,
				std::vector<float> *rc_out=NULL,
				float *err_power=NULL) {
		std::vector<float> R=autocorr<float>(x_beg, x_end, order);
		if(levinson(R, a_out, rc_out, err_power))
			return true;
		if(!R[0])
			return false;

		std::vector<double> a, rc;
		double err;

		if(!levinson(autocorr<double>(x_beg, x_end, order), a_out?&a:NULL, rc_out?&rc:NULL, err_power?&err:NULL))
			return false;

		if(a_out)
			for(size_t i=1; i<a.size(); ++i)
				(*a_out)[i]=(float)a[i];
		if(rc_out)
			for(size_t i=0; i<rc.size(); ++i)
				(*rc_out)[i]=(float)rc[i];
		if(err_power)
			*err_power=(float)err;
		return true;
	}


	/************************************************************************/
	/* Line Spectral Frequencies                                            */
	/************************************************************************/
	namespace {
		template<typename _data_t_>
		_data_t_ FNevChebP(_data_t_ x, const _data_t_ *c, size_t n) {
			_data_t_ b0 = (_data_t_)0.0, b1 = (_data_t_)0.0, b2 = (_data_t_)0.0;
			for (; n; --n) {
				b2 = b1;
				b1 = b0;
				b0 = (_data_t_)2.0 * x * b1 - b2 + c[n-1];
			}
			return (_data_t_)0.5 * (b0 - b2 + c[0]);
		}
	}

	template<typename _data_t_>
	std::vector<_data_t_> poly2lsf(const std::vector<_data_t_> &pc, bool *success=NULL) {
		size_t np = pc.size() - 1;
		std::vector<_data_t_> lsf(np);

		std::vector<_data_t_> fa((np + 1) / 2 + 1), fb((np + 1) / 2 + 1);
		std::vector<_data_t_> ta((np + 1) / 2 + 1), tb((np + 1) / 2 + 1);
		size_t na, nb;

		bool odd = (np % 2 != 0);
		if (odd) {
			nb = (np + 1) / 2;
			na = nb + 1;
		} else {
			nb = np / 2 + 1;
			na = nb;
		}

		fa[0] = (_data_t_)1.0;
		for(size_t i = 1, j = np; i < na; ++i, --j)
			fa[i] = pc[i] + pc[j];

		fb[0] = (_data_t_)1.0;
		for(size_t i = 1, j = np; i < nb; ++i, --j)
			fb[i] = pc[i] - pc[j];

		if (odd) {
			for(size_t i = 2; i < nb; ++i)
				fb[i] = fb[i] + fb[i-2];
		} else {
			for(size_t i = 1; i < na; ++i) {
				fa[i] = fa[i] - fa[i-1];
				fb[i] = fb[i] + fb[i-1];
			}
		}

		ta[0] = fa[na-1];
		for(size_t i = 1, j = na - 2; i < na; ++i, --j)
			ta[i] = (_data_t_)2.0 * fa[j];

		tb[0] = fb[nb-1];
		for(size_t i = 1, j = nb - 2; i < nb; ++i, --j)
			tb[i] = (_data_t_)2.0 * fb[j];

		const size_t NBIS = 4;
		size_t nf = 0, n = na;
		_data_t_ * t = &ta[0];
		_data_t_ dx, xroot = (_data_t_ )2.0;
		_data_t_ xlow = (_data_t_)1.0, xmid, xhigh;
		_data_t_ ylow = FNevChebP(xlow, t, n), ymid, yhigh;

		_data_t_ DW = (_data_t_)0.02 * (_data_t_)M_PI;
		_data_t_ ss = std::sin(DW);
		_data_t_ aa = (_data_t_)4.0 - (_data_t_)4.0 * std::cos(DW)  - ss;
		while (xlow > (_data_t_)-1.0 && nf < np) {
			xhigh = xlow;
			yhigh = ylow;
			dx = aa * xhigh * xhigh + ss;
			xlow = xhigh - dx;
			if (xlow < -1.0)
				xlow = -1.0;
			ylow = FNevChebP(xlow, t, n);
			if (ylow * yhigh <= 0.0) {
				dx = xhigh - xlow;
				for(size_t i = 1; i <= NBIS; ++i) {
					dx = (_data_t_)0.5 * dx;
					xmid = xlow + dx;
					ymid = FNevChebP(xmid, t, n);
					if (ylow * ymid <= 0.0) {
						yhigh = ymid;
						xhigh = xmid;
					} else {
						ylow = ymid;
						xlow = xmid;
					}
				}
				if (yhigh != ylow)
					xmid = xlow + dx * ylow / (ylow - yhigh);
				else
					xmid = xlow + dx;
				lsf[nf] = std::acos(xmid);
				++nf;
				if (xmid >= xroot) {
					xmid = xlow - dx;
				}
				xroot = xmid;
				if (t == &ta[0]) {
					t = &tb[0];
					n = nb;
				} else {
					t = &ta[0];
					n = na;
				}
				xlow = xmid;
				ylow = FNevChebP(xlow, t, n);
			}
		}
		if(success){
			if (nf != np)
				*success=false; //	cout << "poly2lsf: WARNING: failed to find all lsfs" << endl ;
			else
				*success=true;
		}
		return lsf;
	}

	template<typename _data_t_>
	std::vector<_data_t_> lsf2poly(const std::vector<_data_t_> &f) {
		size_t m = f.size();
		std::vector<_data_t_> pc(m + 1);
		_data_t_ c1, c2, *a;
		std::vector<_data_t_> p(m + 1), q(m + 1);

		if(m&1)
			throw std::runtime_error(std::string(__FUNCTION__)+ ": This routine works only for even M.");
		pc[0] = 1.0;
		a = &pc[1];
		size_t mq = m >> 1;
		p[0] = q[0] = (_data_t_)1;
		for(size_t n = 1; n <= mq; ++n) {
			size_t nor = n<<1;
			c1 = (_data_t_)2 * std::cos(f[nor-1]);
			c2 = (_data_t_)2 * std::cos(f[nor-2]);
			for(size_t i = nor; i >= 2; --i) {
				q[i] += q[i-2] - c1 * q[i-1];
				p[i] += p[i-2] - c2 * p[i-1];
			}
			q[1] -= c1;
			p[1] -= c2;
		}
		a[0] = (_data_t_)0.5 * (p[1] + q[1]);
		for(size_t i = 1, n = 2; i < m; ++i, ++n)
			a[i] = (_data_t_)0.5 * (p[i] + p[n] + q[n] - q[i]);

		return pc;
	}


	/************************************************************************/
	/* Linear Prediction Cepstrum Coefficients                              */
	/************************************************************************/
	/// Convert linear prediction coefficients to cepstral coefficients.
	template <typename _data_t_>
	std::vector<_data_t_> poly2cc(const std::vector<_data_t_> &lpc_a, _data_t_ lpc_err_power, size_t lpcc_order) {
		std::vector<_data_t_> cc(lpcc_order), lpc_a_norm;
		const _data_t_ *a;
		size_t lpc_a_sz=lpc_a.size();

		if(lpc_a[0]==1) { // Normalized filter case
			cc[0]=lpc_err_power>0 ? std::log(lpc_err_power) : std::numeric_limits<_data_t_>::min_exponent10*std::log((_data_t_)10); // Take normalized version
			a=&lpc_a[0];
		}
		else { // Unnormalized filter
			cc[0]=lpc_err_power>0 ? std::log(lpc_err_power/(lpc_a[0]*lpc_a[0])) : std::numeric_limits<_data_t_>::min_exponent10*std::log((_data_t_)10);
			lpc_a_norm.resize(lpc_a_sz);
			std::transform(lpc_a.begin(), lpc_a.end(), lpc_a_norm.begin(), std::bind2nd(std::divides<_data_t_>(), lpc_a[0]) );
			a=&lpc_a_norm[0];
		}

		for(size_t m=1, me=std::min(lpc_a_sz,lpcc_order); m<me; ++m) {
			_data_t_ sum=0;
			for(size_t k=1; k<m; ++k)
				sum+=(m-k)*a[k]*cc[m-k];
			cc[m]=-a[m]-sum/m;
		}

		for(size_t m=lpc_a_sz; m<lpcc_order; ++m) {
			_data_t_ sum=0;
			for(size_t k=1; k<lpc_a_sz; ++k)
				sum+=(m-k)*a[k]*cc[m-k];
			cc[m]=-sum/m;
		}

		return cc;
	}
}

#endif // DSP_LPC_H
