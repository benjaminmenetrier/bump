/*
 * (C) Copyright 2013 ECMWF.
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 * In applying this licence, ECMWF does not waive the privileges and immunities
 * granted to it by virtue of its status as an intergovernmental organisation
 * nor does it submit to any jurisdiction.
 */

#pragma once

#include <stddef.h>
#include <vector>
#include "atlas/library/config.h"

//------------------------------------------------------------------------------------------------------

namespace atlas {
namespace array {

class ArrayAlignment {
public:
    ArrayAlignment() : alignment_( 1 ) {}
    ArrayAlignment( int alignment ) : alignment_( alignment ) {}
    operator int() const { return alignment_; }

private:
    int alignment_;
};

class ArrayShape : public std::vector<idx_t> {
private:
    using Base = std::vector<idx_t>;

public:
    ArrayShape() {}
    ArrayShape( Base&& base ) : Base( std::forward<Base>( base ) ) {}
    ArrayShape( std::initializer_list<idx_t> list ) : Base( list ) {}
    ArrayShape( idx_t data[], size_t size ) : Base( data, data + size ) {}
};

inline ArrayShape make_shape( std::initializer_list<idx_t> sizes ) {
    return ArrayShape( sizes );
}
template <typename Int>
inline ArrayShape make_shape( Int size1 ) {
    return ArrayShape{static_cast<idx_t>( size1 )};
}
template <typename Int1, typename Int2>
inline ArrayShape make_shape( Int1 size1, Int2 size2 ) {
    return ArrayShape{static_cast<idx_t>( size1 ), static_cast<idx_t>( size2 )};
}
template <typename Int1, typename Int2, typename Int3>
inline ArrayShape make_shape( Int1 size1, Int2 size2, Int3 size3 ) {
    return ArrayShape{static_cast<idx_t>( size1 ), static_cast<idx_t>( size2 ), static_cast<idx_t>( size3 )};
}
template <typename Int1, typename Int2, typename Int3, typename Int4>
inline ArrayShape make_shape( Int1 size1, Int2 size2, Int3 size3, Int4 size4 ) {
    return ArrayShape{static_cast<idx_t>( size1 ), static_cast<idx_t>( size2 ), static_cast<idx_t>( size3 ),
                      static_cast<idx_t>( size4 )};
}
template <typename Int1, typename Int2, typename Int3, typename Int4, typename Int5>
inline ArrayShape make_shape( Int1 size1, Int2 size2, Int3 size3, Int4 size4, Int5 size5 ) {
    return ArrayShape{static_cast<idx_t>( size1 ), static_cast<idx_t>( size2 ), static_cast<idx_t>( size3 ),
                      static_cast<idx_t>( size4 ), static_cast<idx_t>( size5 )};
}

//------------------------------------------------------------------------------------------------------

}  // namespace array
}  // namespace atlas
