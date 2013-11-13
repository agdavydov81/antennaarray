#ifndef DSP_FFT_H
#define DSP_FFT_H

#include <vector>
#include <complex>
#include <algorithm>
#include <functional>
#include <limits>
#include <string>
#include <stdexcept>
#include "filter.h"

#if !defined(DSP_FFT_MKL) && !defined(DSP_FFT_IPP) && !defined(DSP_FFT_ACML) && !defined(DSP_FFT_FFTW3)
#if   defined(HAVE_MKL)
#define    DSP_FFT_MKL
#elif defined(HAVE_IPP)
#define    DSP_FFT_IPP
#elif defined(HAVE_ACML)
#define    DSP_FFT_ACML
#elif defined(HAVE_FFTW3)
#define    DSP_FFT_FFTW3
#endif
#endif


namespace dsp {
	template<typename _data_t_> class fft_plan;
	template<typename _data_t_> class ifft_plan;

	/************************************************************************/
	/* Real to complex forward FFT                                          */
	/************************************************************************/
	template<typename _data_t_>
	void fft(const _data_t_ *x_beg, size_t n, std::complex<_data_t_> *y, fft_plan<_data_t_> &plan);
	template<typename _data_t_>
	void fft(const _data_t_ *x_beg, size_t n, std::complex<_data_t_> *y) {
		if(!n) return;
		fft_plan<_data_t_> plan;
		fft<_data_t_>(x_beg, n, y, plan);
	}

	template<typename _data_t_>
	void fft(const _data_t_ *x_beg, size_t n, std::vector< std::complex<_data_t_> > &y, fft_plan<_data_t_> &plan) {
		if(!n) { plan.clear(); y.clear(); return; }
		y.resize(n/2+1);
		fft<_data_t_>(x_beg, n, &y[0], plan);
	}
	template<typename _data_t_>
	void fft(const _data_t_ *x_beg, size_t n, std::vector< std::complex<_data_t_> > &y) {
		if(!n) { y.clear(); return; }
		fft_plan<_data_t_> plan;
		fft<_data_t_>(x_beg, n, y, plan);
	}

	template<typename _data_t_>
	void fft(const std::vector<_data_t_> &x, std::vector< std::complex<_data_t_> > &y, fft_plan<_data_t_> &plan) {
		if(x.empty()) { plan.clear(); y.clear(); return; }
		fft<_data_t_>(&x[0], x.size(), y, plan);
	}
	template<typename _data_t_>
	void fft(const std::vector<_data_t_> &x, std::vector< std::complex<_data_t_> > &y) {
		if(x.empty()) { y.clear(); return; }
		fft<_data_t_>(&x[0], x.size(), y);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > fft(const _data_t_ *x_beg, size_t n, fft_plan<_data_t_> &plan) {
		if(!n) { plan.clear(); return std::vector< std::complex<_data_t_> >(); }
		std::vector< std::complex<_data_t_> > y;
		fft<_data_t_>(x_beg, n, y, plan);
		return y;
	}
	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > fft(const _data_t_ *x_beg, size_t n) {
		if(!n) return std::vector< std::complex<_data_t_> >();
		fft_plan<_data_t_> plan;
		return fft<_data_t_>(x_beg, n, plan);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > fft(const std::vector< _data_t_ > &x, fft_plan<_data_t_> &plan) {
		if(x.empty()) { plan.clear(); return std::vector< std::complex<_data_t_> >(); }
		return fft<_data_t_>(&x[0], x.size(), plan);
	}
	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > fft(const std::vector< _data_t_ > &x) {
		if(x.empty()) return std::vector< std::complex<_data_t_> >();
		fft_plan<_data_t_> plan;
		return fft<_data_t_>(x, plan);
	}

	/************************************************************************/
	/* Complex to complex forward FFT                                       */
	/************************************************************************/
	template<typename _data_t_>
	void fft(const std::complex<_data_t_> *x_beg, size_t n, std::complex<_data_t_> *y, fft_plan< std::complex<_data_t_> > &plan);
	template<typename _data_t_>
	void fft(const std::complex<_data_t_> *x_beg, size_t n, std::complex<_data_t_> *y) {
		if(!n) return;
		fft_plan< std::complex<_data_t_> > plan;
		fft<_data_t_>(x_beg, n, y, plan);
	}

	template<typename _data_t_>
	void fft(const std::complex<_data_t_> *x_beg, size_t n, std::vector< std::complex<_data_t_> > &y, fft_plan< std::complex<_data_t_> > &plan) {
		if(!n) { plan.clear(); y.clear(); return; }
		y.resize(n);
		fft<_data_t_>(x_beg, n, &y[0], plan);
	}
	template<typename _data_t_>
	void fft(const std::complex<_data_t_> *x_beg, size_t n, std::vector< std::complex<_data_t_> > &y) {
		if(!n) { y.clear(); return; }
		fft_plan< std::complex<_data_t_> > plan;
		fft<_data_t_>(x_beg, n, y, plan);
	}

	template<typename _data_t_>
	void fft(const std::vector< std::complex<_data_t_> > &x, std::vector< std::complex<_data_t_> > &y, fft_plan< std::complex<_data_t_> > &plan) {
		if(x.empty()) { plan.clear(); y.clear(); return; }
		fft<_data_t_>(&x[0], x.size(), y, plan);
	}
	template<typename _data_t_>
	void fft(const std::vector< std::complex<_data_t_> > &x, std::vector< std::complex<_data_t_> > &y) {
		if(x.empty()) { y.clear(); return; }
		fft<_data_t_>(&x[0], x.size(), y);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > fft(const std::complex<_data_t_> *x_beg, size_t n, fft_plan< std::complex<_data_t_> > &plan) {
		if(!n) { plan.clear(); return std::vector< std::complex<_data_t_> >(); }
		std::vector< std::complex<_data_t_> > y;
		fft<_data_t_>(x_beg, n, y, plan);
		return y;
	}
	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > fft(const std::complex<_data_t_> *x_beg, size_t n) {
		if(!n) return std::vector< std::complex<_data_t_> >();
		fft_plan< std::complex<_data_t_> > plan;
		return fft<_data_t_>(x_beg, n, plan);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > fft(const std::vector< std::complex<_data_t_> > &x, fft_plan< std::complex<_data_t_> > &plan) {
		if(x.empty()) { plan.clear(); return std::vector< std::complex<_data_t_> >(); }
		return fft<_data_t_>(&x[0], x.size(), plan);
	}
	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > fft(const std::vector< std::complex<_data_t_> > &x) {
		if(x.empty()) return std::vector< std::complex<_data_t_> >();
		fft_plan< std::complex<_data_t_> > plan;
		return fft<_data_t_>(x, plan);
	}

	/************************************************************************/
	/* Complex to real backward FFT                                         */
	/************************************************************************/
	template<typename _data_t_>
	void ifft(const std::complex<_data_t_> *x_beg, size_t n, _data_t_ *y, ifft_plan<_data_t_> &plan);
	template<typename _data_t_>
	void ifft(const std::complex<_data_t_> *x_beg, size_t n, _data_t_ *y) {
		if(!n) return;
		ifft_plan<_data_t_> plan;
		ifft<_data_t_>(x_beg, n, y, plan);
	}

	template<typename _data_t_>
	void ifft(const std::complex<_data_t_> *x_beg, size_t n, std::vector< _data_t_ > &y, ifft_plan<_data_t_> &plan) {
		if(!n) { plan.clear(); y.clear(); return; }
		y.resize(x_beg[n-1].imag() ? (n-1)*2+1 : (n-1)*2);
		ifft<_data_t_>(x_beg, n, &y[0], plan);
	}
	template<typename _data_t_>
	void ifft(const std::complex<_data_t_> *x_beg, size_t n, std::vector< _data_t_ > &y) {
		if(!n) { y.clear(); return; }
		ifft_plan<_data_t_> plan;
		ifft<_data_t_>(x_beg, n, y, plan);
	}

	template<typename _data_t_>
	void ifft(const std::vector< std::complex<_data_t_> > &x, std::vector<_data_t_> &y, ifft_plan<_data_t_> &plan) {
		if(x.empty()) { plan.clear(); y.clear(); return; }
		ifft<_data_t_>(&x[0], x.size(), y, plan);
	}
	template<typename _data_t_>
	void ifft(const std::vector< std::complex<_data_t_> > &x, std::vector<_data_t_> &y) {
		if(x.empty()) { y.clear(); return; }
		ifft<_data_t_>(&x[0], x.size(), y);
	}

	template<typename _data_t_>
	std::vector< _data_t_ > ifft(const std::complex<_data_t_> *x_beg, size_t n, ifft_plan<_data_t_> &plan) {
		if(!n) { plan.clear(); return std::vector< _data_t_ >(); }
		std::vector< _data_t_ > y;
		ifft<_data_t_>(x_beg, n, y, plan);
		return y;
	}
	template<typename _data_t_>
	std::vector< _data_t_ > ifft(const std::complex<_data_t_> *x_beg, size_t n) {
		if(!n) return std::vector< _data_t_ >();
		ifft_plan<_data_t_> plan;
		return ifft<_data_t_>(x_beg, n, plan);
	}

	template<typename _data_t_>
	std::vector< _data_t_ > ifft(const std::vector< std::complex<_data_t_> > &x, ifft_plan<_data_t_> &plan) {
		if(x.empty()) { plan.clear(); return std::vector< _data_t_ >(); }
		return ifft<_data_t_>(&x[0], x.size(), plan);
	}
	template<typename _data_t_>
	std::vector< _data_t_ > ifft(const std::vector< std::complex<_data_t_> > &x) {
		if(x.empty()) return std::vector< _data_t_ >();
		ifft_plan<_data_t_> plan;
		return ifft<_data_t_>(x, plan);
	}

	/************************************************************************/
	/* Complex to complex backward FFT                                      */
	/************************************************************************/
	template<typename _data_t_>
	void ifft(const std::complex<_data_t_> *x_beg, size_t n, std::complex<_data_t_> *y, ifft_plan< std::complex<_data_t_> > &plan);
	template<typename _data_t_>
	void ifft(const std::complex<_data_t_> *x_beg, size_t n, std::complex<_data_t_> *y) {
		if(!n) return;
		ifft_plan< std::complex<_data_t_> > plan;
		ifft<_data_t_>(x_beg, n, y, plan);
	}

	template<typename _data_t_>
	void ifft(const std::complex<_data_t_> *x_beg, size_t n, std::vector< std::complex<_data_t_> > &y, ifft_plan< std::complex<_data_t_> > &plan) {
		if(!n) { plan.clear(); y.clear(); return; }
		y.resize(n);
		ifft<_data_t_>(x_beg, n, &y[0], plan);
	}
	template<typename _data_t_>
	void ifft(const std::complex<_data_t_> *x_beg, size_t n, std::vector< std::complex<_data_t_> > &y) {
		if(!n) { y.clear(); return; }
		ifft_plan< std::complex<_data_t_> > plan;
		ifft<_data_t_>(x_beg, n, y, plan);
	}

	template<typename _data_t_>
	void ifft(const std::vector< std::complex<_data_t_> > &x, std::vector< std::complex<_data_t_> > &y, ifft_plan< std::complex<_data_t_> > &plan) {
		if(x.empty()) { plan.clear(); y.clear(); return; }
		ifft<_data_t_>(&x[0], x.size(), y, plan);
	}
	template<typename _data_t_>
	void ifft(const std::vector< std::complex<_data_t_> > &x, std::vector< std::complex<_data_t_> > &y) {
		if(x.empty()) { y.clear(); return; }
		ifft<_data_t_>(&x[0], x.size(), y);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > ifftc(const std::complex<_data_t_> *x_beg, size_t n, ifft_plan< std::complex<_data_t_> > &plan) {
		if(!n) { plan.clear(); return std::vector< std::complex<_data_t_> >(); }
		std::vector< std::complex<_data_t_> > y;
		ifft<_data_t_>(x_beg, n, y, plan);
		return y;
	}
	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > ifftc(const std::complex<_data_t_> *x_beg, size_t n) {
		if(!n) return std::vector< std::complex<_data_t_> >();
		ifft_plan< std::complex<_data_t_> > plan;
		return ifftc<_data_t_>(x_beg, n, plan);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > ifftc(const std::vector< std::complex<_data_t_> > &x, ifft_plan< std::complex<_data_t_> > &plan) {
		if(x.empty()) { plan.clear(); return std::vector< std::complex<_data_t_> >(); }
		return ifftc<_data_t_>(&x[0], x.size(), plan);
	}
	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > ifftc(const std::vector< std::complex<_data_t_> > &x) {
		if(x.empty()) return std::vector< std::complex<_data_t_> >();
		ifft_plan< std::complex<_data_t_> > plan;
		return ifftc<_data_t_>(x, plan);
	}
}

#ifdef DSP_FFT_MKL
/************************************************************************/
/* Intel MKL Fast Fourier Transform calculation routines                */
/************************************************************************/
#include <mkl.h>

namespace dsp {
	template<typename _data_t_>
	class fft_plan {
	public:
		fft_plan(bool explicit_plan_param_ignored_=false) : handle(0), n(0) {}
		fft_plan(const fft_plan &p_) : handle(0), n(0) {
			*this = p_;
		}
		~fft_plan() {
			clear();
		}

		fft_plan & operator = (const fft_plan &p_) {
			if(this==&p_)
				return *this;
			clear();
			n=p_.n;
			MKL_LONG err_code;
			if(n && (err_code=DftiCopyDescriptor(p_.handle, &handle)))
				throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
			return *this;
		}

		void clear() {
			MKL_LONG err_code;
			if(n && (err_code=DftiFreeDescriptor(&handle)))
				throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
			n=0;
		}

		void check(size_t n_, DFTI_CONFIG_VALUE precision_, DFTI_CONFIG_VALUE domain_) {
			if(n==n_)
				return;
			clear();
			n=n_;
			MKL_LONG err_code;
			if(n_) {
				if(err_code=DftiCreateDescriptor(&handle, precision_, domain_, 1, n_))
					throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
				if(err_code=DftiSetValue(handle, DFTI_PLACEMENT, DFTI_NOT_INPLACE))
					throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
				if(err_code=DftiCommitDescriptor(handle))
					throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
			}
		};

		DFTI_DESCRIPTOR_HANDLE handle;
		size_t n;
	};

	template<typename _data_t_>
	class ifft_plan {
	public:
		ifft_plan(bool explicit_plan_param_ignored_=false) : handle(0), n(0) {}
		ifft_plan(const ifft_plan &p_) : handle(0), n(0) {
			*this = p_;
		}
		~ifft_plan() {
			clear();
		}

		ifft_plan & operator = (const ifft_plan &p_) {
			if(this==&p_)
				return *this;
			clear();
			n=p_.n;
			MKL_LONG err_code;
			if(n && (err_code=DftiCopyDescriptor(p_.handle, &handle)))
				throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
			return *this;
		}

		void clear() {
			MKL_LONG err_code;
			if(n && (err_code=DftiFreeDescriptor(&handle)))
				throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
			n=0;
		}

		void check(size_t n_, DFTI_CONFIG_VALUE precision_, DFTI_CONFIG_VALUE domain_) {
			if(n==n_)
				return;
			clear();
			n=n_;
			MKL_LONG err_code;
			if(n_) {
				if(err_code=DftiCreateDescriptor(&handle, precision_, domain_, 1, n_))
					throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
				if(err_code=DftiSetValue(handle, DFTI_PLACEMENT, DFTI_NOT_INPLACE))
					throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
				if(domain_==DFTI_REAL && (err_code=DftiSetValue(handle, DFTI_CONJUGATE_EVEN_STORAGE, DFTI_COMPLEX_COMPLEX)))
					throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
				if(err_code=DftiSetValue(handle, DFTI_BACKWARD_SCALE, 1.0/n_))
					throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
				if(err_code=DftiCommitDescriptor(handle))
					throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code));
			}
		};

		DFTI_DESCRIPTOR_HANDLE handle;
		size_t n;
	};

	#define ___INTERNAL_DSP_MKL_FFT_IMPL(mkr_precision, mkr_domain, mkr_fn)								\
		plan.check(n, mkr_precision, mkr_domain);														\
		MKL_LONG err_code;																				\
		if(n && (err_code=mkr_fn(plan.handle, (void *)x_beg, y)))										\
			throw std::runtime_error(std::string(__FUNCTION__)+": "+ DftiErrorMessage(err_code))

	template<> inline void fft<float>(const float *x_beg, size_t n, std::complex<float> *y, fft_plan<float> &plan)
		{	___INTERNAL_DSP_MKL_FFT_IMPL(DFTI_SINGLE, DFTI_REAL, DftiComputeForward);	}

	template<> inline void fft<double>(const double *x_beg, size_t n, std::complex<double> *y, fft_plan<double> &plan)
		{	___INTERNAL_DSP_MKL_FFT_IMPL(DFTI_DOUBLE, DFTI_REAL, DftiComputeForward);	}

	template<> inline void fft<float>(const std::complex<float> *x_beg, size_t n, std::complex<float> *y, fft_plan< std::complex<float> > &plan)
		{	___INTERNAL_DSP_MKL_FFT_IMPL(DFTI_SINGLE, DFTI_COMPLEX, DftiComputeForward);	}

	template<> inline void fft<double>(const std::complex<double> *x_beg, size_t n, std::complex<double> *y, fft_plan< std::complex<double> > &plan)
		{	___INTERNAL_DSP_MKL_FFT_IMPL(DFTI_DOUBLE, DFTI_COMPLEX, DftiComputeForward);	}

	template<> inline void ifft<float>(const std::complex<float> *x_beg, size_t n, float *y, ifft_plan<float> &plan) {
		n = n ? (x_beg[n-1].imag() ? (n-1)*2+1 : (n-1)*2) : 0;
		___INTERNAL_DSP_MKL_FFT_IMPL(DFTI_SINGLE, DFTI_REAL, DftiComputeBackward);
	}

	template<> inline void ifft<double>(const std::complex<double> *x_beg, size_t n, double *y, ifft_plan<double> &plan) {
		n = n ? (x_beg[n-1].imag() ? (n-1)*2+1 : (n-1)*2) : 0;
		___INTERNAL_DSP_MKL_FFT_IMPL(DFTI_DOUBLE, DFTI_REAL, DftiComputeBackward);
	}

	template<> inline void ifft<float>(const std::complex<float> *x_beg, size_t n, std::complex<float> *y, ifft_plan< std::complex<float> > &plan)
		{	___INTERNAL_DSP_MKL_FFT_IMPL(DFTI_SINGLE, DFTI_COMPLEX, DftiComputeBackward);}

	template<> inline void ifft<double>(const std::complex<double> *x_beg, size_t n, std::complex<double> *y, ifft_plan< std::complex<double> > &plan)
		{	___INTERNAL_DSP_MKL_FFT_IMPL(DFTI_DOUBLE, DFTI_COMPLEX, DftiComputeBackward);}

	inline void * fft_malloc(size_t sz_, size_t align_=16) {
		return mkl_malloc(sz_, (int)align_);
	}

	inline void fft_free(void *ptr_) {
		mkl_free(ptr_);
	}
}

#elif defined(DSP_FFT_IPP)
/************************************************************************/
/* Intel IPP Fast Fourier Transform calculation routines                */
/************************************************************************/
#include <ipp.h>

namespace dsp {
	#define ___INTERNAL_DSP_IPP_PLAN_IMPL(mkr_plan, mkr_data_t, mkr_fntype)									\
	template<>																								\
	class mkr_plan< mkr_data_t > {																			\
	public:																									\
		mkr_plan(bool explicit_plan_=false) : plan(0), buff(0), n(0), hint(explicit_plan_?ippAlgHintFast:ippAlgHintNone) {}	\
		mkr_plan(const mkr_plan &p_) : plan(0), buff(0), n(0), hint(ippAlgHintNone) {						\
			*this = p_;																						\
		}																									\
		~mkr_plan() {																						\
			clear();																						\
		}																									\
																											\
		mkr_plan & operator = (const mkr_plan &p_) {														\
			if(this==&p_)																					\
				return *this;																				\
			clear();																						\
			/* No duplicate plan function. Create plan on next chech() call. */								\
			hint=p_.hint;																					\
			return *this;																					\
		}																									\
																											\
		void clear() {																						\
			if(!n)																							\
				return;																						\
			if(buff)																						\
				ippsFree(buff);																				\
			IppStatus err_code;																				\
			if((err_code=ippsDFTFree ## mkr_fntype(plan))!=ippStsNoErr)										\
				throw std::runtime_error(std::string(__FUNCTION__)+": "+ ippGetStatusString(err_code));		\
			n=0;																							\
		}																									\
																											\
		void check(size_t n_) {																				\
			if(n==n_)																						\
				return;																						\
			clear();																						\
			n=n_;																							\
			if(n) {																							\
				IppStatus err_code;																			\
				if((err_code=ippsDFTInitAlloc ## mkr_fntype(&plan, (int)n, IPP_FFT_DIV_INV_BY_N, hint))!=ippStsNoErr)	\
					throw std::runtime_error(std::string(__FUNCTION__)+": "+ ippGetStatusString(err_code));	\
				int buff_sz;																				\
				if((err_code=ippsDFTGetBufSize ## mkr_fntype(plan, &buff_sz))!=ippStsNoErr)					\
					throw std::runtime_error(std::string(__FUNCTION__)+": "+ ippGetStatusString(err_code));	\
				if(buff_sz) {																				\
					if(!(buff=ippsMalloc_8u(buff_sz)))														\
						throw std::runtime_error(std::string(__FUNCTION__)+": Temporary buffer ippsMalloc_8u allocation error.");	\
				}																							\
				else																						\
					buff=NULL;																				\
			}																								\
		};																									\
																											\
		IppsDFTSpec ## mkr_fntype * plan;																	\
		Ipp8u *buff;																						\
		size_t n;																							\
		IppHintAlgorithm hint;																				\
	}

	___INTERNAL_DSP_IPP_PLAN_IMPL(fft_plan, float,  _R_32f);
	___INTERNAL_DSP_IPP_PLAN_IMPL(fft_plan, double, _R_64f);
	___INTERNAL_DSP_IPP_PLAN_IMPL(fft_plan, std::complex<float>,  _C_32fc);
	___INTERNAL_DSP_IPP_PLAN_IMPL(fft_plan, std::complex<double>, _C_64fc);

	___INTERNAL_DSP_IPP_PLAN_IMPL(ifft_plan, float,  _R_32f);
	___INTERNAL_DSP_IPP_PLAN_IMPL(ifft_plan, double, _R_64f);
	___INTERNAL_DSP_IPP_PLAN_IMPL(ifft_plan, std::complex<float>,  _C_32fc);
	___INTERNAL_DSP_IPP_PLAN_IMPL(ifft_plan, std::complex<double>, _C_64fc);


	#define ___INTERNAL_DSP_IPP_FFT_IMPL(mkr_func, mkr_data_in_t, mkr_data_out_t )									\
		plan.check(n);																								\
		IppStatus err_code;																							\
		if(n && ((err_code=mkr_func((mkr_data_in_t)x_beg, (mkr_data_out_t)y, plan.plan, plan.buff))!=ippStsNoErr))	\
			throw std::runtime_error(std::string(__FUNCTION__)+": "+ ippGetStatusString(err_code))

	template<> inline void fft<float>(const float *x_beg, size_t n, std::complex<float> *y, fft_plan<float> &plan)
		{	___INTERNAL_DSP_IPP_FFT_IMPL(ippsDFTFwd_RToCCS_32f, const float *, Ipp32f *);	}

	template<> inline void fft<double>(const double *x_beg, size_t n, std::complex<double> *y, fft_plan<double> &plan)
		{	___INTERNAL_DSP_IPP_FFT_IMPL(ippsDFTFwd_RToCCS_64f, const double *, Ipp64f *);	}

	template<> inline void fft<float>(const std::complex<float> *x_beg, size_t n, std::complex<float> *y, fft_plan< std::complex<float> > &plan)
		{	___INTERNAL_DSP_IPP_FFT_IMPL(ippsDFTFwd_CToC_32fc, const Ipp32fc *, Ipp32fc *);	}

	template<> inline void fft<double>(const std::complex<double> *x_beg, size_t n, std::complex<double> *y, fft_plan< std::complex<double> > &plan)
		{	___INTERNAL_DSP_IPP_FFT_IMPL(ippsDFTFwd_CToC_64fc, const Ipp64fc *, Ipp64fc *);	}

	template<> inline void ifft<float>(const std::complex<float> *x_beg, size_t n, float *y, ifft_plan<float> &plan) {
		n = n ? (x_beg[n-1].imag() ? (n-1)*2+1 : (n-1)*2) : 0;
		___INTERNAL_DSP_IPP_FFT_IMPL(ippsDFTInv_CCSToR_32f, const Ipp32f *, float *);
	}

	template<> inline void ifft<double>(const std::complex<double> *x_beg, size_t n, double *y, ifft_plan<double> &plan) {
		n = n ? (x_beg[n-1].imag() ? (n-1)*2+1 : (n-1)*2) : 0;
		___INTERNAL_DSP_IPP_FFT_IMPL(ippsDFTInv_CCSToR_64f, const Ipp64f *, double *);
	}

	template<> inline void ifft<float>(const std::complex<float> *x_beg, size_t n, std::complex<float> *y, ifft_plan< std::complex<float> > &plan)
		{	___INTERNAL_DSP_IPP_FFT_IMPL(ippsDFTInv_CToC_32fc, const Ipp32fc *, Ipp32fc *);	}

	template<> inline void ifft<double>(const std::complex<double> *x_beg, size_t n, std::complex<double> *y, ifft_plan< std::complex<double> > &plan)
		{	___INTERNAL_DSP_IPP_FFT_IMPL(ippsDFTInv_CToC_64fc, const Ipp64fc *, Ipp64fc *);	}

	inline void * fft_malloc(size_t sz_) {
		return ippMalloc((int)sz_);
	}

	inline void fft_free(void *ptr_) {
		ippFree(ptr_);
	}
}

#elif defined(DSP_FFT_ACML)
/************************************************************************/
/* AMD ACML Fast Fourier Transform calculation routines                 */
/************************************************************************/
#include <acml.h>

namespace dsp {

	#define ___INTERNAL_DSP_ACML_PLAN_IMPL(mkr_plan, mkr_data_t, mkr_x_def, mkr_x_clear, mkr_x_resize)	\
	template<>																							\
	class mkr_plan< mkr_data_t > {																		\
	public:																								\
		mkr_plan(bool explicit_plan_=false) : explicit_plan(explicit_plan_) {}							\
		mkr_plan(const mkr_plan &p_) : explicit_plan(false) {											\
			*this = p_;																					\
		}																								\
																										\
		mkr_plan & operator = (const mkr_plan &p_) {													\
			if(this==&p_)																				\
				return *this;																			\
			clear(); /* No duplicate plan function. Create plan on next chech() call. */				\
			explicit_plan=p_.explicit_plan;																\
			return *this;																				\
		}																								\
																										\
		void clear() {																					\
			buff.clear();																				\
			mkr_x_clear;																				\
		}																								\
																										\
		bool check(size_t n_, size_t n_x_=0) {															\
			if(buff.size()==n_)																			\
				return false;																			\
			buff.resize(n_);																			\
			mkr_x_resize;																				\
			return true;																				\
		}																								\
																										\
		mkr_x_def;																						\
		std::vector<mkr_data_t> buff;																	\
		bool explicit_plan;																				\
	}

	___INTERNAL_DSP_ACML_PLAN_IMPL(fft_plan, float, std::vector<float> x_copy, x_copy.clear(), x_copy.resize(n_x_));
	___INTERNAL_DSP_ACML_PLAN_IMPL(fft_plan, double, std::vector<double> x_copy, x_copy.clear(), x_copy.resize(n_x_));
	___INTERNAL_DSP_ACML_PLAN_IMPL(fft_plan, std::complex<float>, ;, ;, ;);
	___INTERNAL_DSP_ACML_PLAN_IMPL(fft_plan, std::complex<double>, ;, ;, ;);

	___INTERNAL_DSP_ACML_PLAN_IMPL(ifft_plan, float, std::vector<float> x_copy, x_copy.clear(), x_copy.resize(n_x_));
	___INTERNAL_DSP_ACML_PLAN_IMPL(ifft_plan, double, std::vector<double> x_copy, x_copy.clear(), x_copy.resize(n_x_));
	___INTERNAL_DSP_ACML_PLAN_IMPL(ifft_plan, std::complex<float>, ;, ;, ;);
	___INTERNAL_DSP_ACML_PLAN_IMPL(ifft_plan, std::complex<double>, ;, ;, ;);


	#define ___INTERNAL_DSP_ACML_C2C_IMPL(mkr_func, mkr_arg1, mkr_arg2, mkr_data_t, mkr_plan_sz)	\
		if(!n) {	plan.clear();	return;	}														\
																									\
		int info;																					\
		if(plan.check(mkr_plan_sz)) {																\
			mkr_func(plan.explicit_plan?100:0, mkr_arg2, false, (int)n, (mkr_data_t *)x_beg, 1,		\
				(mkr_data_t *)y, 1, (mkr_data_t *)&plan.buff[0], &info);							\
			if(info)																				\
				throw std::runtime_error(std::string(__FUNCTION__) +								\
						": " #mkr_func " plan function return error.");								\
		}																							\
																									\
		mkr_func(mkr_arg1, mkr_arg2, false, (int)n, (mkr_data_t *)x_beg, 1,							\
			(mkr_data_t *)y, 1, (mkr_data_t *)&plan.buff[0], &info);								\
		if(info)																					\
			throw std::runtime_error(std::string(__FUNCTION__) + 									\
					": " #mkr_func " execution function return error.")

	template<> inline void fft<float>(const std::complex<float> *x_beg, size_t n, std::complex<float> *y, fft_plan< std::complex<float> > &plan)
		{	___INTERNAL_DSP_ACML_C2C_IMPL(cfft1dx, -1, 1.0, complex, 5*n+100);			}

	template<> inline void fft<double>(const std::complex<double> *x_beg, size_t n, std::complex<double> *y, fft_plan< std::complex<double> > &plan)
		{	___INTERNAL_DSP_ACML_C2C_IMPL(zfft1dx, -1, 1.0, doublecomplex, 3*n+100);	}

	template<> inline void ifft<float>(const std::complex<float> *x_beg, size_t n, std::complex<float> *y, ifft_plan< std::complex<float> > &plan)
		{	___INTERNAL_DSP_ACML_C2C_IMPL(cfft1dx, 1, (float)(1.0/n), complex, 5*n+100);}

	template<> inline void ifft<double>(const std::complex<double> *x_beg, size_t n, std::complex<double> *y, ifft_plan< std::complex<double> > &plan)
		{	___INTERNAL_DSP_ACML_C2C_IMPL(zfft1dx, 1, 1.0/n, doublecomplex, 3*n+100);	}


	template<>
	inline void fft<float>(const float *x_beg, size_t n, std::complex<float> *y, fft_plan<float> &plan) {
		if(!n) {	plan.clear();	return;	}

		int info;
		if(plan.check(3*n+100, n)) {
			scfft(plan.explicit_plan?100:0, (int)n, &plan.x_copy[0], &plan.buff[0], &info);
			if(info)
				throw std::runtime_error(std::string(__FUNCTION__)+": scfft plan function return error.");
		}

		std::copy(x_beg, x_beg+n, plan.x_copy.begin());

		scfft(1, (int)n, &plan.x_copy[0], &plan.buff[0], &info);
		if(info)
			throw std::runtime_error(std::string(__FUNCTION__)+": scfft execution function return error.");

		std::transform(plan.x_copy.begin(), plan.x_copy.end(), plan.x_copy.begin(), std::bind2nd(std::multiplies<float>(), std::sqrt((float)n) ) );

		y[0]=std::complex<float>(plan.x_copy[0]);
		std::vector<float>::const_iterator it_re=plan.x_copy.begin()+1, it_im=plan.x_copy.end()-1;
		for(size_t i=1, ie=n/2; i<ie; ++i, ++it_re, --it_im)
			y[i]=std::complex<float>(*it_re, *it_im);
		y[n/2]=(n&1) ? std::complex<float>(*it_re,*it_im) : std::complex<float>(*it_re);
	}

	template<>
	inline void fft<double>(const double *x_beg, size_t n, std::complex<double> *y, fft_plan<double> &plan) {
		if(!n) {	plan.clear();	return;	}

		int info;
		if(plan.check(3*n+100, n)) {
			dzfft(plan.explicit_plan?100:0, (int)n, &plan.x_copy[0], &plan.buff[0], &info);
			if(info)
				throw std::runtime_error(std::string(__FUNCTION__)+": dzfft plan function return error.");
		}

		std::copy(x_beg, x_beg+n, plan.x_copy.begin());

		dzfft(1, (int)n, &plan.x_copy[0], &plan.buff[0], &info);
		if(info)
			throw std::runtime_error(std::string(__FUNCTION__)+": dzfft execution function return error.");

		std::transform(plan.x_copy.begin(), plan.x_copy.end(), plan.x_copy.begin(), std::bind2nd(std::multiplies<double>(), std::sqrt((double)n) ) );

		y[0]=std::complex<double>(plan.x_copy[0]);
		std::vector<double>::const_iterator it_re=plan.x_copy.begin()+1, it_im=plan.x_copy.end()-1;
		for(size_t i=1, ie=n/2; i<ie; ++i, ++it_re, --it_im)
			y[i]=std::complex<double>(*it_re, *it_im);
		y[n/2]=(n&1) ? std::complex<double>(*it_re,*it_im) : std::complex<double>(*it_re);
	}

	template<>
	inline void ifft<float>(const std::complex<float> *x_beg, size_t n, float *y, ifft_plan<float> &plan) {
		if(!n) {	plan.clear();	return;	}

		bool is_odd=x_beg[n-1].imag()!=0;
		n = is_odd ? (n-1)*2+1 : (n-1)*2;

		int info;
		if(plan.check(3*n+100, n)) {
			csfft(plan.explicit_plan?100:0, (int)n, &plan.x_copy[0], &plan.buff[0], &info);
			if(info)
				throw std::runtime_error(std::string(__FUNCTION__)+": csfft plan function return error.");
		}

		plan.x_copy[0]=x_beg[0].real();
		++x_beg;
		std::vector<float>::iterator it_re=plan.x_copy.begin()+1, it_im=plan.x_copy.end()-1;
		for(size_t i=1, ie=n/2; i<ie; ++i, ++it_re, --it_im, ++x_beg) {
			*it_re=x_beg->real();
			*it_im=x_beg->imag();
		}
		*it_re=x_beg->real();
		if(is_odd)
			*it_im=x_beg->imag();

		csfft(1, (int)n, &plan.x_copy[0], &plan.buff[0], &info);
		if(info)
			throw std::runtime_error(std::string(__FUNCTION__)+": csfft execution function return error.");

		std::transform(plan.x_copy.begin(), plan.x_copy.end(), plan.x_copy.begin(), std::bind2nd(std::divides<float>(), std::sqrt((float)n) ) );

		*y=plan.x_copy.front();
		std::copy(plan.x_copy.rbegin(), plan.x_copy.rend()-1, y+1);
	}

	template<>
	inline void ifft<double>(const std::complex<double> *x_beg, size_t n, double *y, ifft_plan<double> &plan) {
		if(!n) {	plan.clear();	return;	}

		bool is_odd=x_beg[n-1].imag()!=0;
		n = is_odd ? (n-1)*2+1 : (n-1)*2;

		int info;
		if(plan.check(3*n+100, n)) {
			zdfft(plan.explicit_plan?100:0, (int)n, &plan.x_copy[0], &plan.buff[0], &info);
			if(info)
				throw std::runtime_error(std::string(__FUNCTION__)+": zdfft plan function return error.");
		}

		plan.x_copy[0]=x_beg[0].real();
		++x_beg;
		std::vector<double>::iterator it_re=plan.x_copy.begin()+1, it_im=plan.x_copy.end()-1;
		for(size_t i=1, ie=n/2; i<ie; ++i, ++it_re, --it_im, ++x_beg) {
			*it_re=x_beg->real();
			*it_im=x_beg->imag();
		}
		*it_re=x_beg->real();
		if(is_odd)
			*it_im=x_beg->imag();

		zdfft(1, (int)n, &plan.x_copy[0], &plan.buff[0], &info);
		if(info)
			throw std::runtime_error(std::string(__FUNCTION__)+": zdfft execution function return error.");

		std::transform(plan.x_copy.begin(), plan.x_copy.end(), plan.x_copy.begin(), std::bind2nd(std::divides<double>(), std::sqrt((double)n) ) );

		*y=plan.x_copy.front();
		std::copy(plan.x_copy.rbegin(), plan.x_copy.rend()-1, y+1);
	}

	#pragma message("FFT Warning: ACML dos not provide functions for aligned memory allocation. Standart malloc and free functions will be used.")
	inline void * fft_malloc(size_t sz_) {
		return malloc(sz_);
	}

	inline void fft_free(void *ptr_) {
		free(ptr_);
	}
}

#elif defined(DSP_FFT_FFTW3)
/************************************************************************/
/* FFTW3 Fast Fourier Transform calculation routines                    */
/* !CAUTION! FFTW natively do not support multi threaded plan creation  */
/* deletion but allow multi threaded  plan execution. So programmer     */
/* must create a critical section for plan creation and delete or use   */
/* safe wrapper.                                                        */
/************************************************************************/
#include <fftw_safe.h>

namespace dsp {
	#define ___INTERNAL_DSP_FFTW3_PLAN_IMPL(mkr_plan, mkr_plan_expr, mkr_prefix, mkr_make_plan_expr, mkr_data_in_t, mkr_data_out_t)	\
	template<>																					\
	class mkr_plan_expr {																		\
	public:																						\
		mkr_plan(bool explicit_plan_=false) : plan(0), n(0), fftw_flag(explicit_plan_?FFTW_MEASURE:FFTW_ESTIMATE) {}	\
		mkr_plan(const mkr_plan &p_) : plan(0), n(0), fftw_flag(FFTW_ESTIMATE) {				\
			*this = p_;																			\
		}																						\
		~mkr_plan() {																			\
			clear();																			\
		}																						\
																								\
		mkr_plan & operator = (const mkr_plan &p_) {											\
			if(this==&p_)																		\
				return *this;																	\
			clear();																			\
			/* No duplicate plan function. Create plan on next chech() call. */					\
			fftw_flag=p_.fftw_flag;																\
			return *this;																		\
		}																						\
																								\
		void clear() {																			\
			if(n) {																				\
				safe_ ## mkr_prefix ## _destroy_plan(plan);										\
				plan=NULL;																		\
				n=0;																			\
			}																					\
		}																						\
																								\
		void check(size_t n_, const mkr_data_in_t *x_, mkr_data_out_t *y_, size_t x_raw_sz_) {	\
			if(n==n_)																			\
				return;																			\
			clear();																			\
			n=n_;																				\
			if(n) {																				\
				std::vector< mkr_data_in_t > x_bak;												\
				if(fftw_flag!=FFTW_ESTIMATE)													\
					x_bak.assign(x_, x_+x_raw_sz_);												\
				if(n_ && (!(plan=mkr_make_plan_expr)))											\
					throw std::runtime_error(std::string(__FUNCTION__)+": Can't create plan.");	\
				if(fftw_flag!=FFTW_ESTIMATE)													\
					std::copy(x_bak.begin(), x_bak.end(), (mkr_data_in_t *)x_);					\
			}																					\
		};																						\
																								\
		mkr_prefix ## _plan plan;																\
		size_t n;																				\
		unsigned fftw_flag;																		\
	}

	___INTERNAL_DSP_FFTW3_PLAN_IMPL(fft_plan, fft_plan<float>, fftwf, safe_fftwf_plan_dft_r2c_1d((int)n_, (float *)x_, (fftwf_complex *)y_, fftw_flag), float,  std::complex<float>);
	___INTERNAL_DSP_FFTW3_PLAN_IMPL(fft_plan, fft_plan<double>, fftw, safe_fftw_plan_dft_r2c_1d( (int)n_, (double *)x_, (fftw_complex *)y_, fftw_flag), double, std::complex<double>);
	___INTERNAL_DSP_FFTW3_PLAN_IMPL(fft_plan, fft_plan< std::complex<float> >, fftwf, safe_fftwf_plan_dft_1d((int)n_, (fftwf_complex *)x_, (fftwf_complex *)y_, FFTW_FORWARD, fftw_flag), std::complex<float>,  std::complex<float>);
	___INTERNAL_DSP_FFTW3_PLAN_IMPL(fft_plan, fft_plan< std::complex<double> >, fftw, safe_fftw_plan_dft_1d( (int)n_, (fftw_complex  *)x_, (fftw_complex  *)y_, FFTW_FORWARD, fftw_flag), std::complex<double>, std::complex<double>);

	___INTERNAL_DSP_FFTW3_PLAN_IMPL(ifft_plan, ifft_plan<float>, fftwf, safe_fftwf_plan_dft_c2r_1d((int)n_, (fftwf_complex *)x_, y_, fftw_flag), std::complex<float>,  float);
	___INTERNAL_DSP_FFTW3_PLAN_IMPL(ifft_plan, ifft_plan<double>, fftw, safe_fftw_plan_dft_c2r_1d( (int)n_, (fftw_complex  *)x_, y_, fftw_flag), std::complex<double>, double);
	___INTERNAL_DSP_FFTW3_PLAN_IMPL(ifft_plan, ifft_plan< std::complex<float> >, fftwf, safe_fftwf_plan_dft_1d((int)n_, (fftwf_complex *)x_, (fftwf_complex *)y_, FFTW_BACKWARD, fftw_flag), std::complex<float>,  std::complex<float>);
	___INTERNAL_DSP_FFTW3_PLAN_IMPL(ifft_plan, ifft_plan< std::complex<double> >, fftw, safe_fftw_plan_dft_1d( (int)n_, (fftw_complex  *)x_, (fftw_complex  *)y_, FFTW_BACKWARD, fftw_flag), std::complex<double>, std::complex<double>);


	template<> inline void fft<float>(const float *x_beg, size_t n, std::complex<float> *y, fft_plan<float> &plan) {
		plan.check(n, x_beg, y, n);
		if(n) safe_fftwf_execute_dft_r2c(plan.plan, const_cast<float *>(x_beg), (fftwf_complex *)y);
	}

	template<> inline void fft<double>(const double *x_beg, size_t n, std::complex<double> *y, fft_plan<double> &plan) {
		plan.check(n, x_beg, y, n);
		if(n) safe_fftw_execute_dft_r2c(plan.plan, const_cast<double *>(x_beg), (fftw_complex *)y);
	}

	template<> inline void fft<float>(const std::complex<float> *x_beg, size_t n, std::complex<float> *y, fft_plan< std::complex<float> > &plan) {
		plan.check(n, x_beg, y, n);
		if(n) safe_fftwf_execute_dft(plan.plan, (fftwf_complex *)x_beg, (fftwf_complex *)y);
	}

	template<> inline void fft<double>(const std::complex<double> *x_beg, size_t n, std::complex<double> *y, fft_plan< std::complex<double> > &plan) {
		plan.check(n, x_beg, y, n);
		if(n) safe_fftw_execute_dft(plan.plan, (fftw_complex *)x_beg, (fftw_complex *)y);
	}

	template<> inline void ifft<float>(const std::complex<float> *x_beg, size_t n, float *y, ifft_plan<float> &plan) {
		if(!n) { plan.clear(); return; }
		size_t n_y = x_beg[n-1].imag() ? (n-1)*2+1 : (n-1)*2;
		plan.check(n_y, x_beg, y, n);
		safe_fftwf_execute_dft_c2r(plan.plan, (fftwf_complex *)x_beg, y);
		std::transform(y, y+n_y, y, std::bind2nd(std::divides<float>(),n_y));
	}

	template<> inline void ifft<double>(const std::complex<double> *x_beg, size_t n, double *y, ifft_plan<double> &plan) {
		if(!n) { plan.clear(); return; }
		size_t n_y = x_beg[n-1].imag() ? (n-1)*2+1 : (n-1)*2;
		plan.check(n_y, x_beg, y, n);
		safe_fftw_execute_dft_c2r(plan.plan, (fftw_complex *)x_beg, y);
		std::transform(y, y+n_y, y, std::bind2nd(std::divides<double>(),n_y));
	}

	template<> inline void ifft<float>(const std::complex<float> *x_beg, size_t n, std::complex<float> *y, ifft_plan< std::complex<float> > &plan) {
		if(!n) { plan.clear(); return; }
		plan.check(n, x_beg, y, n);
		safe_fftwf_execute_dft(plan.plan, (fftwf_complex *)x_beg, (fftwf_complex *)y);
		std::transform(y, y+n, y, std::bind2nd(std::divides< std::complex<float> >(),n));
	}

	template<> inline void ifft<double>(const std::complex<double> *x_beg, size_t n, std::complex<double> *y, ifft_plan< std::complex<double> > &plan) {
		if(!n) { plan.clear(); return; }
		plan.check(n, x_beg, y, n);
		safe_fftw_execute_dft(plan.plan, (fftw_complex *)x_beg, (fftw_complex *)y);
 		std::transform(y, y+n, y, std::bind2nd(std::divides< std::complex<double> >(),n));
	}

	inline void * fft_malloc(size_t sz_) {
		return safe_fftwf_malloc(sz_);
	}

	inline void fft_free(void *ptr_) {
		safe_fftwf_free(ptr_);
	}
}

#else

#error No FFT implementation selected.

#endif


	/************************************************************************/
	/* Some useful classes and functions, based on FFT:                     */
	/*  - Overlap-Save filtering class                                      */
	/*  - FREQZ functions                                                   */
	/*  - XCORR function                                                    */
	/************************************************************************/
namespace dsp {
	/************************************************************************/
	/* FFT Overlap-Save filtering class for FIR filters                     */
	/************************************************************************/
	template <typename _fft_data_precision_, typename _data_in_t_, typename _data_out_t_>
	class fftfilt {
	public:
		fftfilt()
			:FFT_N(32), h(1,1), H(NULL), x(NULL), X(NULL), y(NULL), plan_x2X(true), plan_X2y(true) {
		}
		fftfilt(const std::vector<_fft_data_precision_> & h_, size_t FFT_N_=0, bool fft_explicit_plan_=true)
			:FFT_N(0), h(h_), H(NULL), x(NULL), X(NULL), y(NULL), plan_x2X(fft_explicit_plan_), plan_X2y(fft_explicit_plan_) {
			calc_FFT_N(FFT_N_);
		}
		~fftfilt() {
			free_data();
		}

/**		\brief Lazy initialization method. Call also reset for real memory allocation.
*/		void init(const std::vector<_fft_data_precision_> & h_, size_t FFT_N_=0) {
			free_data();
			h=h_;
			calc_FFT_N(FFT_N_);
		}

		void reset() {
			if(!H) {
				alloc_data();
				return;
			}

			std::copy(h.begin(), h.end(), x);
			std::fill(x+h.size(), x+FFT_N, (_fft_data_precision_)0);

			fft(x, FFT_N, X, plan_x2X);

			std::copy(X, X+FFT_N/2+1, H);

			x_pos=h.size()-1;
			std::fill(x, x+x_pos, (_fft_data_precision_)0);
		}

/**	\brief	Return only FFT Overlap-Save method delay! Filter delay must be calculated by other means.
*/		size_t delay() const {
			return h.size()<=1 ? 0 : FFT_N-h.size()+1;
		}

		size_t get_fft_size() const {
			return FFT_N;
		}

		const std::vector<_fft_data_precision_> & get_filter() const {
			return h;
		}

/**	\brief				Overlap-Save filtering function.
	\param	data_in_	Input data pointer.
	\param	data_in_size_	Input data size (number of samples).
	\param	data_out_	Output data pointer. !Caution! Safe in-place filtering allowed only if data processed by
						frames equals delay() size. In out-of-place general filtering case data_out_ must
						point to buffer with size data_in_size_+delay().
	\return				Number of successfully processed samples in output buffer.
*/		size_t filter(const _data_in_t_ * data_in_, size_t data_in_size_, _data_out_t_ * data_out_) {
			if(h.size()<=1) {
				if(h.empty() || (h.size()==1 && h.front()==(_fft_data_precision_)1))
					for(size_t i=0; i<data_in_size_; ++i, ++data_in_, ++data_out_)
						filter_out_type_cast(*data_in_, *data_out_);
				else
					for(size_t i=0; i<data_in_size_; ++i, ++data_in_, ++data_out_)
						filter_out_type_cast(*data_in_*h.front(), *data_out_);
				return data_in_size_;
			}

			if(!H)
				alloc_data();

			size_t data_out_size=0,min_x,delay_sz=delay(),overlap_sz=FFT_N-delay_sz;
			while(data_in_size_) {
				min_x=std::min(FFT_N-x_pos, data_in_size_);
				std::transform(data_in_, data_in_+min_x, x+x_pos, in_type_cast);
				x_pos+=min_x;
				data_in_+=min_x;
				data_in_size_-=min_x;

				if(x_pos==FFT_N) {
					if(data_in_size_) { // Input-output arrays overlap checking
						bool do_throw=false;
						if((const void *)data_out_<(const void *)data_in_) {
							if((const void *)(data_out_+delay_sz)>(const void *)data_in_)
								do_throw=true;
						}
						else {
							if((const void *)data_out_<(const void *)(data_in_+data_in_size_))
								do_throw=true;
						}
						if(do_throw)
							throw std::invalid_argument(std::string(__FUNCTION__)+": In place processing safely allowed only by frames equals to delay() samples.");
					}

					fft(x, FFT_N, X, plan_x2X);

					std::transform(X, X+FFT_N/2+1, H, X, std::multiplies< std::complex<_fft_data_precision_> >());

					ifft(X, FFT_N/2+1, y, plan_X2y);

					for(const _fft_data_precision_ *ptr_beg=y+overlap_sz, *ptr_end=y+FFT_N; ptr_beg!=ptr_end; ++ptr_beg, ++data_out_)
						filter_out_type_cast(*ptr_beg, *data_out_);

					data_out_size+=delay_sz;

					std::copy(x+delay_sz, x+FFT_N, x);
					x_pos=overlap_sz;
				}
			}
			return data_out_size;
		}

	protected:
		fftfilt(const fftfilt &);
		fftfilt & operator= (const fftfilt &);

		static _fft_data_precision_ in_type_cast(_data_in_t_ x) {
			return static_cast<_fft_data_precision_>(x);
		}

		void calc_FFT_N(size_t FFT_N_=0) {
			double N_log2 = ceil(log2((double)h.size()));
			if(FFT_N_)
				N_log2 = std::max( N_log2, floor(log2((double)FFT_N_)+0.5) );
			else
				N_log2 = std::max( 5.0, N_log2+1 );
			FFT_N = (size_t)1 << (size_t)N_log2;
		}

		void free_data() {
			plan_x2X.clear();
			plan_X2y.clear();
			if(y) {	fft_free(y);			y=NULL;	}
			if(X) {	fft_free((void *)X);	X=NULL;	}
			if(x) {	fft_free(x);			x=NULL;	}
			if(H) {	fft_free((void *)H);	H=NULL;	}
		}

		void alloc_data() {
			free_data(); // Not necessary, but let it be

			try {
				if(!( H = (std::complex<_fft_data_precision_> *)fft_malloc((FFT_N/2+1)*sizeof(*H)) ))
					throw "Filter frequency response buffer allocation error.";

				if(!( x = (_fft_data_precision_ *)fft_malloc(  FFT_N * sizeof(*x)) ))
					throw "Signal buffer allocation error.";

				if(!( X = (std::complex<_fft_data_precision_> *)fft_malloc((FFT_N/2+1)*sizeof(*X)) ))
					throw "Signal frequency response buffer allocation error.";

				if(!( y = (_fft_data_precision_ *)fft_malloc(  FFT_N * sizeof(*y)) ))
					throw "iFFT output buffer allocation error.";
			}
			catch(const char * err) {
				free_data();
				throw std::runtime_error(std::string(__FUNCTION__)+": "+err);
			}

			reset();
		}

		size_t FFT_N, x_pos;

		std::vector<_fft_data_precision_> h;
		std::complex<_fft_data_precision_> *H, *X;
		_fft_data_precision_ *x,*y;
		fft_plan<_fft_data_precision_> plan_x2X;
		ifft_plan<_fft_data_precision_> plan_X2y;
	};

	/************************************************************************/
	/* FREQZ filter response calculation function                           */
	/************************************************************************/
	template<typename _data_t_>
	struct freqz_memory {
		freqz_memory() : x(NULL), X(NULL), x_sz(0), zeros_pos(0) {}
		~freqz_memory() {	clear();	}
		void clear() {
			x2X.clear();
			if(X) {		fft_free(X);	X=NULL;		}
			if(x) {		fft_free(x);	x=NULL;		}
			x_sz=0;
		}
		void check(size_t x_sz_) {
			if(x_sz==x_sz_)
				return;
			clear();
			if(x_sz_) {
				if( !(x=(_data_t_ *)fft_malloc(x_sz_*sizeof(*x))) ||
					!(X=(std::complex<_data_t_> *)fft_malloc((x_sz_/2+1)*sizeof(*X))) )
					throw std::runtime_error(std::string(__FUNCTION__)+": Memory allocation error.");
				x_sz=x_sz_;
				zeros_pos=x_sz_;
			}
		}
		void calc_fft(const std::vector<_data_t_> &b) {
			size_t b_sz=std::min(b.size(), x_sz);
			std::copy(b.begin(), b.begin()+b_sz, x);
			if(b_sz<zeros_pos)
				std::fill(x+b_sz, x+zeros_pos, (_data_t_)0);
			zeros_pos=b_sz;
			fft(x, x_sz, X, x2X);
		}
		_data_t_ *x;
		std::complex<_data_t_> *X;
		fft_plan<_data_t_> x2X;
		size_t x_sz, zeros_pos;
	};

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > freqz(const std::vector<_data_t_> &b, const std::vector<_data_t_> &a, size_t nfft=512) {
		freqz_memory<_data_t_> mem;
		return freqz(b, a, nfft, mem);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > freqz(const std::vector<_data_t_> &b, const std::vector<_data_t_> &a, size_t nfft, freqz_memory<_data_t_> &mem) {
		std::vector< std::complex<_data_t_> > H(nfft);
		mem.check(2*nfft);

		if(b.size()>1) {
			mem.calc_fft(b);
			if(a.size()<=1) {
				if(a.empty() || a.front()==(_data_t_)1) // normalized FIR filter
					std::copy(mem.X, mem.X+nfft, H.begin());
				else {                                   // unnormalized FIR filter
					typename std::vector< std::complex<_data_t_> >::iterator it_out=H.begin();
					_data_t_ a_front=a.front();
					for(const std::complex<_data_t_> *it=mem.X, *ie=mem.X+nfft; it!=ie; ++it, ++it_out)
						*it_out = *it / a_front;
//					std::transform(mem.X, mem.X+nfft, H.begin(), std::bind2nd(std::divides< std::complex<_data_t_> >(), a.front()) );
//					the ABI of passing structure with complex float member has changed in GCC 4.4
				}
				return H;
			}
			else
				std::copy(mem.X, mem.X+nfft, H.begin());
		}
		if(a.size()>1) {
			mem.calc_fft(a);
			if(b.size()<=1) {
				typename std::vector< std::complex<_data_t_> >::iterator it_out=H.begin();
				_data_t_ b_front=b.empty()?(_data_t_)1:b.front();
				for(const std::complex<_data_t_> *it=mem.X, *ie=mem.X+nfft; it!=ie; ++it, ++it_out)
					*it_out = b_front / *it;
//				std::transform(mem.X, mem.X+nfft, H.begin(), std::bind1st(std::divides< std::complex<_data_t_> >(), b.empty()?(_data_t_)1:b.front()) );
//				the ABI of passing structure with complex float member has changed in GCC 4.4
			}
			else
				transform(H.begin(), H.end(), mem.X, H.begin(), std::divides< std::complex<_data_t_> >());
			return H;
		}

		std::fill(H.begin(), H.end(), (b.empty()?(_data_t_)1:b.front()) / (a.empty()?(_data_t_)1:a.front()) );
		return H;
	}

	/************************************************************************/
	/* XCORR cross-correlation calculation functions                        */
	/************************************************************************/
	enum xcorr_type {
		exc_none,			// no scaling (this is the default)
		exc_biased,			// scales the raw cross-correlation by 1/M
		exc_unbiased,		// scales the raw correlation by 1/(M-abs(lags))
		exc_unbiased_sqrt	// scales the raw correlation by 1/sqrt(M-abs(lags))
	};

	template<typename _x_precision_, typename _x_data_t_>
	struct xcorr_memory {
		xcorr_memory() : x(NULL), X1(NULL), X2(NULL), x_sz(0), zeros_pos(0), min_lag(0), max_lag(0), M(0), xc_type(exc_none) {}
		~xcorr_memory() {	clear();	}
		void clear() {
			x2X.clear();
			if(X2) {	fft_free(X2);	X2=NULL;	}
			if(X1) {	fft_free(X1);	X1=NULL;	}
			if(x) {		fft_free(x);	x=NULL;		}
			x_sz=0;
		}
		void check(size_t x_sz_, size_t X_sz_, xcorr_type xc_type_, ptrdiff_t min_lag_, ptrdiff_t max_lag_, ptrdiff_t M_) {
			if(x_sz!=x_sz_) {
				clear();
				if(x_sz_) {
					if( !(x=(_x_data_t_ *)fft_malloc(x_sz_*sizeof(*x))) ||
						!(X1=(std::complex<_x_precision_> *)fft_malloc(X_sz_*sizeof(*X1))) ||
						!(X2=(std::complex<_x_precision_> *)fft_malloc(X_sz_*sizeof(*X2)))  )
						throw std::runtime_error(std::string(__FUNCTION__)+": Memory allocation error.");
					x_sz=x_sz_;
					zeros_pos=x_sz_;
				}
			}

			if( xc_type!=xc_type_ || (xc_type!=exc_none && (min_lag!=min_lag_ || max_lag!=max_lag_ || M!=M_) ) ) {
				xc_type=xc_type_;
				min_lag=min_lag_;
				max_lag=max_lag_;
				M=M_;

				if(xc_type==exc_none)
					lag_factors.clear();
				else
					lag_factors.resize(max_lag-min_lag+1);
				typename std::vector<_x_precision_>::iterator lag_it=lag_factors.begin();

				switch(xc_type) {
				case exc_none:			// no scaling (this is the default)
					break;
				case exc_biased:		// scales the raw cross-correlation by 1/M
					std::fill(lag_factors.begin(), lag_factors.end(), (_x_precision_)1/M);
					break;
				case exc_unbiased:		// scales the raw correlation by 1/(M-abs(lags))
					for(ptrdiff_t l=min_lag; l<=max_lag; ++l, ++lag_it)
						*lag_it=(_x_precision_)1/(M-std::abs(l));
					break;
				case exc_unbiased_sqrt:	// scales the raw correlation by 1/sqrt(M-abs(lags))
					for(ptrdiff_t l=min_lag; l<=max_lag; ++l, ++lag_it)
						*lag_it=std::sqrt((_x_precision_)1/(M-std::abs(l)));
					break;
				default:
					throw std::runtime_error(std::string(__FUNCTION__)+": Unknown scaling option.");
				}
			}
		}

		void calc_fft(const _x_data_t_ *x_in, size_t x_in_sz, std::complex<_x_precision_> *X /* Must be either X1 or X2 */) {
			x_in_sz=std::min(x_in_sz, x_sz);
			if(x_in_sz)
				std::copy(x_in, x_in+x_in_sz, x);
			if(x_in_sz<zeros_pos)
				std::fill(x+x_in_sz, x+zeros_pos, (_x_data_t_)0);
			zeros_pos=x_in_sz;
			fft(x, x_sz, X, x2X);
		}

		_x_data_t_ *x;
		std::complex<_x_precision_> *X1, *X2;
		fft_plan<_x_data_t_> x2X;
		ifft_plan<_x_data_t_> X2x;
		size_t x_sz, zeros_pos;
		std::vector<_x_precision_> lag_factors;
		ptrdiff_t min_lag, max_lag, M;
		xcorr_type xc_type;

		static _x_precision_ abs_pow2(const std::complex<_x_precision_> &x) {
			return x.real()*x.real()+x.imag()*x.imag();
		}
		static std::complex<_x_precision_> conj_mul(const std::complex<_x_precision_> &x, const std::complex<_x_precision_> &y) {
			return x*std::conj(y);
		}
	};

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > xcorr(const std::complex<_data_t_> *x1, size_t x1_size,
												const std::complex<_data_t_> *x2, size_t x2_size,
												xcorr_type xc_type,
												ptrdiff_t min_lag, ptrdiff_t max_lag,
												xcorr_memory< _data_t_, std::complex<_data_t_> > &mem) {
		size_t nfft2=2*nextpower2(std::max(x1_size,x2_size));
		if(!nfft2)
			return std::vector< std::complex<_data_t_> > ();
		ptrdiff_t M=(ptrdiff_t)(std::max(x1_size,x2_size));
		min_lag=std::max(min_lag,-M+1);
		max_lag=std::min(max_lag,M-1);

		mem.check(nfft2, nfft2, xc_type, min_lag, max_lag, M);
		mem.calc_fft(x1,x1_size,mem.X1);

		if(x1==x2 && x1_size==x2_size) { // Autocorrelation case
			std::transform(mem.X1, mem.X1+nfft2, mem.X1, mem.abs_pow2);
		}
		else { // Cross-correlation case
			mem.calc_fft(x2,x2_size,mem.X2);
			std::transform(mem.X1, mem.X1+nfft2, mem.X2, mem.X1, mem.conj_mul);
		}

		std::complex<_data_t_> *xc=mem.X2;
		ifft(mem.X1, nfft2, xc, mem.X2x);

		std::vector< std::complex<_data_t_> > ret(max_lag-min_lag+1);
		typename std::vector< std::complex<_data_t_> >::iterator ret_it=ret.begin(), ret_end=ret.end();
		if(min_lag<0) {
			std::copy(xc+nfft2+min_lag,xc+nfft2,ret_it);
			ret_it+=-min_lag;
			min_lag=0;
		}
		std::copy(xc+min_lag, xc+max_lag+1, ret_it);

		if(!mem.lag_factors.empty()) {
			ret_it=ret.begin();
			for(typename std::vector<_data_t_>::iterator lag_it=mem.lag_factors.begin(); ret_it!=ret_end; ++ret_it, ++lag_it)
				*ret_it*=*lag_it;
		}

		return ret;
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > xcorr(const std::complex<_data_t_> *x1, size_t x1_size,
												const std::complex<_data_t_> *x2, size_t x2_size,
												xcorr_type xc_type=exc_none,
												ptrdiff_t min_lag=std::numeric_limits<ptrdiff_t>::min(),
												ptrdiff_t max_lag=std::numeric_limits<ptrdiff_t>::max()) {
		xcorr_memory< _data_t_, std::complex<_data_t_> > mem;
		return xcorr(x1,x1_size, x2,x2_size, xc_type, min_lag,max_lag, mem);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > xcorr(const std::complex<_data_t_> *x, size_t x_size) {
		return xcorr(x,x_size, x,x_size);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > xcorr(const std::vector< std::complex<_data_t_> > &x1,
												const std::vector< std::complex<_data_t_> > &x2,
												xcorr_type xc_type, ptrdiff_t min_lag, ptrdiff_t max_lag,
												xcorr_memory< _data_t_, std::complex<_data_t_> > &mem) {
		return xcorr(x1.empty()?NULL:&x1[0], x1.size(),
					 x2.empty()?NULL:&x2[0], x2.size(),
					 xc_type, min_lag, max_lag, mem);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > xcorr(const std::vector< std::complex<_data_t_> > &x1,
												const std::vector< std::complex<_data_t_> > &x2,
												xcorr_type xc_type=exc_none,
												ptrdiff_t min_lag=std::numeric_limits<ptrdiff_t>::min(),
												ptrdiff_t max_lag=std::numeric_limits<ptrdiff_t>::max()) {
		xcorr_memory< _data_t_, std::complex<_data_t_> > mem;
		return xcorr(x1,x2,xc_type,min_lag,max_lag,mem);
	}

	template<typename _data_t_>
	std::vector< std::complex<_data_t_> > xcorr(const std::vector< std::complex<_data_t_> > &x) {
		return xcorr(x, x);
	}


	template<typename _data_t_>
	std::vector<_data_t_> xcorr(const _data_t_ *x1, size_t x1_size,
								const _data_t_ *x2, size_t x2_size,
								xcorr_type xc_type,
								ptrdiff_t min_lag, ptrdiff_t max_lag,
								xcorr_memory<_data_t_,_data_t_> &mem) {
		size_t nfft=nextpower2(std::max(x1_size,x2_size));
		if(!nfft)
			return std::vector<_data_t_> ();
		ptrdiff_t M=(ptrdiff_t)(std::max(x1_size,x2_size));
		min_lag=std::max(min_lag,-M+1);
		max_lag=std::min(max_lag,M-1);

		mem.check(2*nfft, nfft+1, xc_type, min_lag, max_lag, M);
		mem.calc_fft(x1,x1_size,mem.X1);

		if(x1==x2 && x1_size==x2_size) { // Autocorrelation case
			std::transform(mem.X1, mem.X1+nfft+1, mem.X1, mem.abs_pow2);
		}
		else { // Cross-correlation case
			mem.calc_fft(x2,x2_size,mem.X2);
			std::transform(mem.X1, mem.X1+nfft+1, mem.X2, mem.X1, mem.conj_mul);
		}

		_data_t_ *xc=(_data_t_ *)mem.X2;
		ifft(mem.X1, nfft+1, xc, mem.X2x);

		std::vector<_data_t_> ret(max_lag-min_lag+1);
		typename std::vector<_data_t_>::iterator ret_it=ret.begin();
		if(min_lag<0) {
			std::copy(xc+2*nfft+min_lag,xc+2*nfft,ret_it);
			ret_it+=-min_lag;
			min_lag=0;
		}
		std::copy(xc+min_lag, xc+max_lag+1, ret_it);

		if(!mem.lag_factors.empty())
			std::transform(ret.begin(), ret.end(), mem.lag_factors.begin(), ret.begin(), std::multiplies<_data_t_>());

		return ret;
	}

	template<typename _data_t_>
	std::vector<_data_t_> xcorr(const _data_t_ *x1, size_t x1_size,
								const _data_t_ *x2, size_t x2_size,
								xcorr_type xc_type=exc_none,
								ptrdiff_t min_lag=std::numeric_limits<ptrdiff_t>::min(),
								ptrdiff_t max_lag=std::numeric_limits<ptrdiff_t>::max()) {
		xcorr_memory<_data_t_,_data_t_> mem;
		return xcorr(x1,x1_size, x2,x2_size, xc_type, min_lag,max_lag, mem);
	}

	template<typename _data_t_>
	std::vector<_data_t_> xcorr(const _data_t_ *x, size_t x_size) {
		return xcorr(x,x_size, x,x_size);
	}

	template<typename _data_t_>
	std::vector<_data_t_> xcorr(const std::vector<_data_t_> &x1,
								const std::vector<_data_t_> &x2,
								xcorr_type xc_type,
								ptrdiff_t min_lag, ptrdiff_t max_lag,
								xcorr_memory<_data_t_,_data_t_> &mem) {
		return xcorr(x1.empty()?NULL:&x1[0], x1.size(),
					 x2.empty()?NULL:&x2[0], x2.size(),
					 xc_type, min_lag, max_lag, mem);
	}

	template<typename _data_t_>
	std::vector<_data_t_> xcorr(const std::vector<_data_t_> &x1,
								const std::vector<_data_t_> &x2,
								xcorr_type xc_type=exc_none,
								ptrdiff_t min_lag=std::numeric_limits<ptrdiff_t>::min(),
								ptrdiff_t max_lag=std::numeric_limits<ptrdiff_t>::max()) {
		xcorr_memory<_data_t_,_data_t_> mem;
		return xcorr(x1, x2, xc_type, min_lag, max_lag, mem);
	}

	template<typename _data_t_>
	std::vector<_data_t_> xcorr(const std::vector<_data_t_> &x) {
		return xcorr(x, x);
	}
}

#endif // DSP_FFT_H
