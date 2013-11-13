#ifndef __RANDOM_MT19937__
#define __RANDOM_MT19937__

#include <math.h>

#ifdef __cplusplus
namespace MT19937 {
#endif

//******************************************** Mersenne Twister; period 2**19937-1 ***********************************
/* A C-program for MT19937: Real number version([0,1)-interval) (1998/4/6) */
/*   genrand() generates one pseudorandom real number (double) */
/* which is uniformly distributed on [0,1)-interval, for each  */
/* call. sgenrand(seed) set initial values to the working area */
/* of 624 words. Before genrand(), sgenrand(seed) must be      */
/* called once. (seed is any 32-bit integer except for 0).     */
/* Integer generator is obtained by modifying two lines.       */
/*   Coded by Takuji Nishimura, considering the suggestions by */
/* Topher Cooper and Marc Rieffel in July-Aug. 1997.           */

/* This library is free software; you can redistribute it and/or   */
/* modify it under the terms of the GNU Library General Public     */
/* License as published by the Free Software Foundation; either    */
/* version 2 of the License, or (at your option) any later         */
/* version.                                                        */
/* This library is distributed in the hope that it will be useful, */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of  */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.            */
/* See the GNU Library General Public License for more details.    */
/* You should have received a copy of the GNU Library General      */
/* Public License along with this library; if not, write to the    */
/* Free Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA   */ 
/* 02111-1307  USA                                                 */

/* Copyright (C) 1997 Makoto Matsumoto and Takuji Nishimura.       */
/* When you use this, send an email to: matumoto@math.keio.ac.jp   */
/* with an appropriate reference to your work.                     */

/* REFERENCE                                                       */
/* M. Matsumoto and T. Nishimura,                                  */
/* "Mersenne Twister: A 623-Dimensionally Equidistributed Uniform  */
/* Pseudo-Random Number Generator",                                */
/* ACM Transactions on Modeling and Computer Simulation,           */
/* Vol. 8, No. 1, January 1998, pp 3--30.                          */

/* Period parameters */  
//#define N 624
//#define M 397
//#define MATRIX_A 0x9908b0df   /* constant vector a */
//#define UPPER_MASK 0x80000000 /* most significant w-r bits */
//#define LOWER_MASK 0x7fffffff /* least significant r bits */

/* Tempering parameters */   
/*#define TEMPERING_MASK_B 0x9d2c5680
#define TEMPERING_MASK_C 0xefc60000
#define TEMPERING_SHIFT_U(y)  (y >> 11)
#define TEMPERING_SHIFT_S(y)  (y << 7)
#define TEMPERING_SHIFT_T(y)  (y << 15)
#define TEMPERING_SHIFT_L(y)  (y >> 18)
*/
static unsigned long MT19937_mt[624]; /* the array for the state vector  */
static int MT19937_mti=624+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
inline void sgenrand(unsigned long seed){
	/* setting initial seeds to mt[N] using         */
	/* the generator Line 25 of Table 1 in          */
	/* [KNUTH 1981, The Art of Computer Programming */
	/*    Vol. 2 (2nd Ed.), pp102]                  */
	MT19937_mt[0]= seed & 0xffffffff;
	for (MT19937_mti=1; MT19937_mti<624; MT19937_mti++)
		MT19937_mt[MT19937_mti] = (69069 * MT19937_mt[MT19937_mti-1]) & 0xffffffff;
}

inline unsigned long genrand(void){
	unsigned long y;
	static const unsigned long mag01[2]={0x0,0x9908b0df};
	/* mag01[x] = x * MATRIX_A  for x=0,1 */

	if (MT19937_mti >= 624) { /* generate N words at one time */
		int kk;

		if (MT19937_mti == 624+1)   /* if sgenrand() has not been called, */
			sgenrand(4357); /* a default initial seed is used   */

		for (kk=0;kk<624-397;kk++) {
			y = (MT19937_mt[kk]&0x80000000)|(MT19937_mt[kk+1]&0x7fffffff);
			MT19937_mt[kk] = MT19937_mt[kk+397] ^ (y >> 1) ^ mag01[y & 0x1];
		}
		for (;kk<624-1;kk++) {
			y = (MT19937_mt[kk]&0x80000000)|(MT19937_mt[kk+1]&0x7fffffff);
			MT19937_mt[kk] = MT19937_mt[kk+(397-624)] ^ (y >> 1) ^ mag01[y & 0x1];
		}
		y = (MT19937_mt[624-1]&0x80000000)|(MT19937_mt[0]&0x7fffffff);
			MT19937_mt[624-1] = MT19937_mt[397-1] ^ (y >> 1) ^ mag01[y & 0x1];

		MT19937_mti = 0;
	}

	y = MT19937_mt[MT19937_mti++];
	y ^= (y >> 11);
	y ^= (y <<  7) & 0x9d2c5680;
	y ^= (y << 15) & 0xefc60000;
	y ^= (y >> 18);

	return y; /* for integer generation */
}

inline double rand() { /* uniform [0,1) distribution */
	return ( (double)genrand() * 2.3283064365386963e-10 ); /* reals: [0,1)-interval */
}

#ifndef M_PI
#define M_PI        3.1415926535897932384626433832795
#endif
#ifndef M_2PI
#define M_2PI		6.283185307159586476925286766559
#endif

// Box-Muller normal distribution generation method
inline double randn(double *second_randn=NULL) {
	double U1;
	do {			/* if U1==0, then the log() below will blow up */
		U1=rand();
	}while(U1==0);
	double d1=sqrt(-2 * log(U1));
	double U2=rand();

	if(second_randn)
		*second_randn=d1*sin(M_2PI*U2);
	return d1*cos(M_2PI*U2);
}

#ifdef __cplusplus	// namespace MT19937
}
#endif

#endif