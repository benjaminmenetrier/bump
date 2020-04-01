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

#include <functional>
#include <initializer_list>
#include <string>

#include "atlas/domain/Domain.h"
#include "atlas/library/config.h"
#include "atlas/projection/Projection.h"
#include "atlas/util/ObjectHandle.h"

namespace eckit {
class Hash;
}
namespace atlas {
class PointXY;
class PointLonLat;
namespace util {
class Config;
}
namespace grid {
class IterateXY;
class IterateLonLat;
namespace detail {
namespace grid {
class Grid;
}
}  // namespace detail
}  // namespace grid
}  // namespace atlas

namespace atlas {

//---------------------------------------------------------------------------------------------------------------------

class Grid : public util::ObjectHandle<grid::detail::grid::Grid> {
public:
    using Config        = util::Config;
    using Spec          = util::Config;
    using Domain        = atlas::Domain;
    using Projection    = atlas::Projection;
    using PointXY       = atlas::PointXY;      // must be sizeof(double)*2
    using PointLonLat   = atlas::PointLonLat;  // must be sizeof(double)*2
    using IterateXY     = grid::IterateXY;
    using IterateLonLat = grid::IterateLonLat;
    using Predicate     = std::function<bool( long )>;

public:
    IterateXY xy( Predicate p ) const;
    IterateXY xy() const;
    IterateLonLat lonlat() const;

    using Handle::Handle;
    Grid() = default;
    Grid( const std::string& name, const Domain& = Domain() );
    Grid( const Grid&, const Domain& );
    Grid( const Config& );

    bool operator==( const Grid& other ) const { return uid() == other.uid(); }
    bool operator!=( const Grid& other ) const { return uid() != other.uid(); }

    idx_t size() const;

    const Projection& projection() const;
    const Domain& domain() const;
    RectangularLonLatDomain lonlatBoundingBox() const;
    std::string name() const;
    std::string uid() const;

    /// Adds to the hash the information that makes this Grid unique
    void hash( eckit::Hash& h ) const;

    Spec spec() const;
};

//---------------------------------------------------------------------------------------------------------------------

}  // namespace atlas
