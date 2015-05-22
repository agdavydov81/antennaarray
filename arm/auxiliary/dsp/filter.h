#ifndef DSP_FILTER_H
#define DSP_FILTER_H

#include <vector>
#include <algorithm>
#include <functional>
#include <numeric>
#include <limits>
#include <complex>
#include <cmath>
#include <string>
#include <stdexcept>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#if defined _MSC_VER && _MSC_VER < 1600
namespace std {
	inline __int64 abs(__int64 x) {
		return x>=0 ? x : -x;
	}
}
#endif


namespace dsp {
	/************************************************************************/
	/* Round functions                                                      */
	/************************************************************************/
	inline float round(float x) {
		return floor(x + 0.5f);
	}
	inline double round(double x) {
		return floor(x + 0.5);
	}

	/************************************************************************/
	/* Base-2 logarithm (ITPP)                                              */
	/************************************************************************/
#ifndef log2
	inline long double log2(long double x) {
		return std::log(x) * 1.442695040888963387004650940070860087871551513671875l;
	}

	inline double log2(double x) {
		return std::log(x) * 1.442695040888963387004650940070860087871551513671875;
	}

	inline float log2(float x) {
		return std::log(x) * 1.442695040888963387004650940070860087871551513671875f;
	}
#endif // log2

	/************************************************************************/
	/* Window generation functions                                          */
	/************************************************************************/
	template<typename _data_t_>
	inline std::vector<_data_t_> hamming(size_t order) {
		std::vector<_data_t_> w(order);
		for (size_t i=0; i<=order/2; ++i)
			w[order-1-i] = w[i] = (_data_t_)(0.54-0.46*std::cos(2*M_PI*i/(order-1)));
		return w;
	}

	template<typename _data_t_>
	inline std::vector<_data_t_> gausswin(size_t order) {
		double a = 2.5;
		std::vector<_data_t_> w(order);
		double n2 = (double)(order-1)/2;
		for (size_t i=0; i<=order/2; ++i) {
			double t = a*(i-n2)/n2;
			w[order-1-i] = w[i] = (_data_t_)std::exp(-0.5*t*t);
		}
		return w;
	}

	template<typename _data_t_>
	inline std::vector<_data_t_> blackman(size_t order) {
		std::vector<_data_t_> w(order);
		w[order-1] = w[0] = 0;
		for (size_t i = 1; i<=order/2; ++i)
			w[order-1-i] = w[i] = (_data_t_)(0.42 - 0.5 * std::cos(2.0 * M_PI * i / (order - 1)) + 0.08 * std::cos(4.0 * M_PI * i / (order - 1)));
		return w;
	}

	template<typename _data_t_>
	inline std::vector<_data_t_> blackmanharris(size_t order) {
		std::vector<_data_t_> w(order);
		for (size_t i = 0; i<=order/2; ++i)
			w[order-1-i] = w[i] = (_data_t_)(0.35875 - 0.48829*std::cos(2*M_PI*i/(order-1)) + 0.14128*std::cos(4*M_PI*i/(order-1)) - 0.01168*std::cos(6*M_PI*i/(order-1)));
		return w;
	}

	/************************************************************************/
	/* Roundup functions                                                    */
	/************************************************************************/
/**	\brief Function return roundup to nearest power of 2: nextpower2(7)==8; nextpower2(8)==8; nextpower2(9)==16.
*/	inline size_t nextpower2(size_t x) {
		if(!x) return 0;
		size_t bit_cnt=0;
		size_t is_round_up=0;
		while(x>1) {
			is_round_up=std::max(is_round_up, x&1);
			++bit_cnt;
			x>>=1;
		}
		return (size_t)1<<(bit_cnt+is_round_up);
	}

/**	\brief Function return roundup to nearest product of input factors: 3^a*4^b*7^c*... - x -> min
	Example: nextfactor(19,[3 4 7])==21
	\param factors - [3 4 7]. Any values. For example primes.
	\param factors_sz - factors number.
	\return Product. In example 3^a*4^b*7^c.
*/	inline size_t nextfactor(size_t x_, const size_t *factors, size_t factors_sz) {
		if(!x_ || !factors_sz)
			return 0;

		size_t cur_fact=factors[0], cur_prod=1, cur_x=x_, cur_bits=0;
		if(cur_fact<=1)
			throw std::runtime_error(std::string(__FUNCTION__)+": factor must be greater of one.");

		while(cur_x>1) {
			cur_x=(cur_x+cur_fact-1)/cur_fact;
			cur_prod*=cur_fact;
			cur_bits++;
		}
		if(factors_sz==1)
			return cur_prod;

		size_t best_prod=std::numeric_limits<size_t>::max();
		cur_x=x_;
		cur_prod=1;
		for (size_t i=0; i<=cur_bits; ++i) {
			best_prod=std::min(best_prod, cur_prod*nextfactor(cur_x,factors+1,factors_sz-1));
			cur_x=(cur_x+cur_fact-1)/cur_fact;
			cur_prod*=cur_fact;
		}

		return best_prod;
	}

	/************************************************************************/
	/* FIR Filters design block                                             */
	/************************************************************************/
/**	\brief			Design Hamming-window based lowpass linear-phase FIR filter.
	\param	order	Desired filter order rounds up to nearest odd.
	\param	fc		Normalized cutoff frequency in the range between 0 and 1,
					where 1 corresponds to the Nyquist frequency.
	\return			Returns vector containing the coefficients of an filter.
*/	template<typename _data_t_>
	std::vector<_data_t_> design_fir_lp(size_t order, double fc) {
		std::vector<_data_t_> out_h;
		if(fc<0.0 || fc>1.0 || order<1)
			throw std::invalid_argument(std::string(__FUNCTION__)+": Incorrect arguments.");

		size_t order2=order>>1;
		out_h.resize((order2<<1)+1);

		double pi_n;
		typename std::vector<_data_t_>::iterator h_out_it=out_h.begin()+order2;
		*h_out_it++=(_data_t_)fc;
		for (size_t n=1; n<=order2; ++n, ++h_out_it) {
			pi_n = M_PI * n;
			*h_out_it=(_data_t_)( (0.54+0.46*cos(pi_n/order2)) * sin(pi_n*fc)/pi_n );
		}

		std::copy(out_h.rbegin(), out_h.rbegin()+order2, out_h.begin());
		return out_h;
	}

/**	\brief			Design Hamming-window based highpass linear-phase FIR filter.
	\param	order	Desired filter order rounds up to nearest odd.
	\param	fc		Normalized cutoff frequency in the range between 0 and 1,
					where 1 corresponds to the Nyquist frequency.
	\return			Returns vector containing the coefficients of an filter.
*/	template<typename _data_t_>
	std::vector<_data_t_> design_fir_hp(size_t order, double fc) {
		std::vector<_data_t_> out_h;
		if(fc<0.0 || fc>1.0 || order<1)
			throw std::invalid_argument(std::string(__FUNCTION__)+": Incorrect arguments.");

		size_t order2=order>>1;
		out_h.resize((order2<<1)+1);

		double pi_n;
		typename std::vector<_data_t_>::iterator h_out_it=out_h.begin()+order2;
		*h_out_it++=(_data_t_)(1.0-fc);
		for (size_t n=1; n<=order2; ++n, ++h_out_it) {
			pi_n = M_PI * n;
			*h_out_it=(_data_t_)( (0.54+0.46*cos(pi_n/order2)) * -sin(pi_n*fc)/pi_n );
		}

		std::copy(out_h.rbegin(), out_h.rbegin()+order2, out_h.begin());
		return out_h;
	}

/**	\brief			Design Hamming-window based bandpass linear-phase FIR filter.
	\param	order	Desired filter order rounds up to nearest odd.
	\param	fc1		Normalized cutoff frequency in the range between 0 and fc2.
	\param	fc2		Normalized cutoff frequency in the range between fc1 and 1,
					where 1 corresponds to the Nyquist frequency.
	\return			Returns vector containing the coefficients of an filter.
*/	template<typename _data_t_>
	std::vector<_data_t_> design_fir_bp(size_t order, double fc1, double fc2) {
		std::vector<_data_t_> out_h;
		if(fc1<0.0 || fc1>1.0 || fc2<0.0 || fc2>1.0 || fc1>=fc2 || order<1)
			throw std::invalid_argument(std::string(__FUNCTION__)+": Incorrect arguments.");

		size_t order2=order>>1;
		out_h.resize((order2<<1)+1);

		double pi_n;
		typename std::vector<_data_t_>::iterator h_out_it=out_h.begin()+order2;
		*h_out_it++=(_data_t_)(fc2-fc1);
		for (size_t n=1; n<=order2; ++n, ++h_out_it) {
			pi_n = M_PI * n;
			*h_out_it=(_data_t_)( (0.54+0.46*cos(pi_n/order2)) * (sin(pi_n*fc2)-sin(pi_n*fc1))/pi_n );
		}

		std::copy(out_h.rbegin(), out_h.rbegin()+order2, out_h.begin());
		return out_h;
	}

/**	\brief			Design Hamming-window based bandstop linear-phase FIR filter.
	\param	order	Desired filter order rounds up to nearest odd.
	\param	fc1		Normalized cutoff frequency in the range between 0 and fc2.
	\param	fc2		Normalized cutoff frequency in the range between fc1 and 1,
					where 1 corresponds to the Nyquist frequency.
	\return			Returns vector containing the coefficients of an filter.
*/	template<typename _data_t_>
	std::vector<_data_t_> design_fir_bs(size_t order, double fc1, double fc2) {
		std::vector<_data_t_> out_h;
		if(fc1<0.0 || fc1>1.0 || fc2<0.0 || fc2>1.0 || fc1>=fc2 || order<1)
			throw std::invalid_argument(std::string(__FUNCTION__)+": Incorrect arguments.");

		size_t order2=order>>1;
		out_h.resize((order2<<1)+1);

		double pi_n;
		typename std::vector<_data_t_>::iterator h_out_it=out_h.begin()+order2;
		*h_out_it++=(_data_t_)(1.0-(fc2-fc1));
		for (size_t n=1; n<=order2; ++n, ++h_out_it) {
			pi_n = M_PI * n;
			*h_out_it=(_data_t_)( (0.54+0.46*cos(pi_n/order2)) * (sin(pi_n*fc1)-sin(pi_n*fc2))/pi_n );
		}

		std::copy(out_h.rbegin(), out_h.rbegin()+order2, out_h.begin());
		return out_h;
	}


	/************************************************************************/
	/* Filtering functions block                                            */
	/************************************************************************/
	template<typename _data_t_>
	class filter_memory {
	public:
		filter_memory(size_t mem_add_ = 32)
			: mem_add(mem_add_) {
		}
		filter_memory(const filter_memory &filt_) {
			*this = filt_;
		}

		filter_memory & operator = (const filter_memory &filt_) {
			if(this==&filt_)
				return *this;

			mem_add	= filt_.mem_add;
			mem_pos	= filt_.mem_pos;
			x_mem	= filt_.x_mem;
			y_mem	= filt_.y_mem;

			return *this;
		}

		typename std::vector<_data_t_>::const_iterator x_begin() const {
			return x_mem.begin()+mem_pos;
		}
		typename std::vector<_data_t_>::const_iterator y_begin() const {
			return y_mem.begin()+mem_pos+1;
		}

		void clear() {
			x_mem.clear();
			y_mem.clear();
		}

		void check_size(size_t b_size_, size_t a_size_) {
			if(x_mem.size()==(b_size_>1?b_size_+mem_add:0) && y_mem.size()==(a_size_>1?a_size_+mem_add:0))
				return;

			x_mem.clear();
			if(b_size_>1)
				x_mem.resize(b_size_+mem_add);
			y_mem.clear();
			if(a_size_>1)
				y_mem.resize(a_size_+mem_add);
			mem_pos=mem_add;
		}

		void x_set(_data_t_ x) {
			x_mem[mem_pos]=x;
		}
		void y_set(_data_t_ y) {
			y_mem[mem_pos]=y;
		}

		void x_fill(_data_t_ x) {
			std::fill(x_mem.begin(), x_mem.end(), x);
		}
		void y_fill(_data_t_ y) {
			std::fill(y_mem.begin(), y_mem.end(), y);
		}

		void mem_shift() {
			if(mem_pos)
				mem_pos--;
			else {
				mem_pos=mem_add;
				if(x_mem.size())
					std::copy(x_mem.begin(), x_mem.begin()+x_mem.size()-mem_add-1, x_mem.begin()+mem_add+1);
				if(y_mem.size())
					std::copy(y_mem.begin(), y_mem.begin()+y_mem.size()-mem_add-1, y_mem.begin()+mem_add+1);
			}
		}

	protected:
		// Additional filter memory size. Depends on std::copy function performance.
		// Only one std::copy call in filt_mem_add loop iterations.
		size_t mem_add;

		size_t mem_pos;

		std::vector<_data_t_> x_mem, y_mem;
	};

	template <typename _in_t_, typename _out_t_>
	void filter_out_type_cast(_in_t_ const &x_, _out_t_ &y_) {
		y_ = static_cast<_out_t_>( std::min(std::max(x_, (_in_t_)std::numeric_limits<_out_t_>::min()), (_in_t_)std::numeric_limits<_out_t_>::max()) );
	}
	template <typename _in_t_>
	void filter_out_type_cast(_in_t_ const &x_, float &y_) {
		y_ = static_cast<float>(x_);
	}
	template <typename _in_t_>
	void filter_out_type_cast(_in_t_ const &x_, double &y_) {
		y_ = static_cast<double>(x_);
	}

	template<typename _data_internal_t_, typename _InIt, typename _OutIt>
	inline void filter(const std::vector<_data_internal_t_> &b, const std::vector<_data_internal_t_> &a,
		_InIt x_beg, _InIt x_end, _OutIt y_beg) {

        filter_memory<_data_internal_t_> filt_mem;
        filter(b, a, x_beg, x_end, y_beg, filt_mem);
    }

	template<typename _data_internal_t_, typename _InIt, typename _OutIt>
	void filter(const std::vector<_data_internal_t_> &b, const std::vector<_data_internal_t_> &a,
		_InIt x_beg, _InIt x_end, _OutIt y_beg, filter_memory<_data_internal_t_> &filt_mem) {
		// 	a(0)*y(n) = b(0)*x(n) + b(1)*x(n-1) + ... + b(N_b)*x(n-N_b)    - a(1)*y(n-1) - ... - a(N_a)*y(n-N_a)

		if(a.empty() && b.empty()) {
			filt_mem.clear();
			for (; x_beg!=x_end; ++x_beg, ++y_beg)
				filter_out_type_cast(*x_beg, *y_beg);
			return;
		}

		if(!a.empty() && a.front()!=(_data_internal_t_)1) { // filter coefficients normalizations
			std::vector<_data_internal_t_> b_n(b.size()), a_n(a.size());
			std::transform(b.begin(), b.end(), b_n.begin(), std::bind2nd(std::divides<_data_internal_t_>(), a.front()));
			std::transform(a.begin(), a.end(), a_n.begin(), std::bind2nd(std::divides<_data_internal_t_>(), a.front()));
			return filter(b_n, a_n, x_beg, x_end, y_beg, filt_mem);
		}

		filt_mem.check_size(b.size(), a.size());

		if(a.size()<=1) {
			/************************************************************************/
			/* FIR filter                                                           */
			/************************************************************************/
			// FIR filter
			for (; x_beg!=x_end; ++x_beg, ++y_beg) {
				filt_mem.x_set((_data_internal_t_)*x_beg);
				filter_out_type_cast(std::inner_product(b.begin(), b.end(), filt_mem.x_begin(), (_data_internal_t_)0), *y_beg);
				filt_mem.mem_shift();
			}
		} else if(b.size()<=1) {
			/************************************************************************/
			/* Allpole filter                                                       */
			/************************************************************************/
			if(b.empty() || b[0]==(_data_internal_t_)1) { // Allpole filter and b[0]==1
				for (; x_beg!=x_end; ++x_beg, ++y_beg) {
					_data_internal_t_ y_val=(_data_internal_t_)(*x_beg-std::inner_product(a.begin()+1, a.end(), filt_mem.y_begin(), (_data_internal_t_)0));
					filt_mem.y_set(y_val);
					filter_out_type_cast(y_val,*y_beg);
					filt_mem.mem_shift();
				}
			}
			else { // Allpole filter, but b[0]!=1
				for (; x_beg!=x_end; ++x_beg, ++y_beg) {
					_data_internal_t_ y_val=(_data_internal_t_)(*x_beg*b[0]-std::inner_product(a.begin()+1, a.end(), filt_mem.y_begin(), (_data_internal_t_)0));
					filt_mem.y_set(y_val);
					filter_out_type_cast(y_val,*y_beg);
					filt_mem.mem_shift();
				}
			}
		} else {
			/************************************************************************/
			/* Common case filter                                                   */
			/************************************************************************/
			for (; x_beg!=x_end; ++x_beg, ++y_beg) {
				filt_mem.x_set((_data_internal_t_)*x_beg);
				_data_internal_t_ y_val=(_data_internal_t_)(
								 std::inner_product(b.begin(),  b.end(), filt_mem.x_begin(),
								-std::inner_product(a.begin()+1,a.end(), filt_mem.y_begin(), (_data_internal_t_)0) ) );
				filt_mem.y_set(y_val);
				filter_out_type_cast(y_val,*y_beg);
				filt_mem.mem_shift();
			}
		}
	}

	/************************************************************************/
	/* Median function and median filter                                    */
	/************************************************************************/
	template<typename _It>
	inline typename _It::value_type median(const _It& beg, const _It& end)
	{
		std::vector<typename _It::value_type> t(beg, end);
		std::sort(t.begin(), t.end());
		size_t sz = t.size();
		if ((sz)%2)
			return t[sz/2];
		else
			return (t[sz/2-1]+t[sz/2])/2;
	}

	template<typename _data_internal_t_, typename _InIt, typename _OutIt>
	void median_filter(size_t order,
					   _InIt x_beg, _InIt x_end, _OutIt y_beg,
					   filter_memory<_data_internal_t_> &filt_mem=filter_memory<_data_internal_t_>()) {

		filt_mem.check_size(order, 1);

		for (; x_beg!=x_end; ++x_beg, ++y_beg) {
			filt_mem.x_set((_data_internal_t_)*x_beg);
			*y_beg=	filter_out_type_cast<_data_internal_t_,typename _OutIt::value_type>()(
				median(filt_mem.x_begin(), filt_mem.x_begin()+order));
			filt_mem.mem_shift();
		}
	}

	/************************************************************************/
	/* Convolution function -- useful to merge filters chain in one filter  */
	/************************************************************************/
	template<typename _data_t_>
	std::vector<_data_t_> conv(const std::vector<_data_t_> &x1, const std::vector<_data_t_> &x2) {
		/* Allpole and FIR filters special case */
		if(x1.empty())
			return x2;
		if(x2.empty())
			return x1;

		std::vector<_data_t_> y(x1.size()+x2.size()-1);

		typename std::vector<_data_t_>::const_iterator it_x1=x1.begin();
		typename std::vector<_data_t_>::const_reverse_iterator it_x2=x2.rend()-1;
		size_t min_sz=std::min(x1.size(), x2.size()), x1_bord=x2.size()-1;
		for (size_t i=0, y_sz=y.size(); i<y_sz; ++i) {
			y[i]=inner_product(it_x1, it_x1+std::min(min_sz,std::min(i+1,y_sz-i)), it_x2, (_data_t_)0);
			if(i>=x1_bord)
				++it_x1;
			if(it_x2!=x2.rbegin())
				--it_x2;
		}

		return y;
	}

} //namespace dsp

#endif // DSP_FILTER_H
