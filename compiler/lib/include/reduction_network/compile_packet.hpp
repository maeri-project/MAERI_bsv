/******************************************************************************
Copyright (c) 2019 Georgia Instititue of Technology

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Author: Hyoukjun Kwon (hyoukjun@gatech.edu)

*******************************************************************************/

#ifndef RN_COMPILER_PACKET_H_
#define RN_COMPILER_PACKET_H_

namespace MAERI {
  namespace ReductionNetwork {
    class CompilePacket {
      protected:
        bool is_valid_ = false;
        int vn_id_;
        int vn_size_;
        int num_accumulated_psums_;

      public:
        CompilePacket () :
          vn_id_(-1),
          vn_size_(-1),
          num_accumulated_psums_(-1),
          is_valid_(false) {
        }

        CompilePacket (int vn_id, int vn_size, int num_accumulated_psums) :
          vn_id_(vn_id),
          vn_size_(vn_size),
          num_accumulated_psums_(num_accumulated_psums),
          is_valid_(true) {
        }

        bool IsValid() {
          return is_valid_;
        }

        void Invalidate() {
          is_valid_ = false;
        }

        int GetVNID() {
          return vn_id_;
        }

        int GetVNSize() {
          return vn_size_;
        }

        int GetNumPSums() {
          return num_accumulated_psums_;
        }

    }; //End of class CompilePacket
  };  // End of namespace ReductionNetwork
};  // End of namespace MAERI

#endif
