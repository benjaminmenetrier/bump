/*
 * (C) Copyright 2013 ECMWF.
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 * In applying this licence, ECMWF does not waive the privileges and immunities
 * granted to it by virtue of its status as an intergovernmental organisation
 * nor does it submit to any jurisdiction.
 */

#include "atlas/grid/detail/partitioner/MatchingMeshPartitionerSphericalPolygon.h"

#include <vector>

#include "eckit/log/ProgressTimer.h"

#include "atlas/grid/Grid.h"
#include "atlas/grid/Iterator.h"
#include "atlas/mesh/Nodes.h"
#include "atlas/parallel/mpi/mpi.h"
#include "atlas/runtime/Exception.h"
#include "atlas/runtime/Log.h"
#include "atlas/util/SphericalPolygon.h"

namespace atlas {
namespace grid {
namespace detail {
namespace partitioner {

namespace {
PartitionerBuilder<MatchingMeshPartitionerSphericalPolygon> __builder( "spherical-polygon" );
}

void MatchingMeshPartitionerSphericalPolygon::partition( const Grid& grid, int partitioning[] ) const {
    const eckit::mpi::Comm& comm = atlas::mpi::comm();
    const int mpi_rank           = int( comm.rank() );
    const int mpi_size           = int( comm.size() );

    ATLAS_TRACE( "MatchingMeshPartitionerSphericalPolygon::partition" );

    ATLAS_ASSERT( grid.domain().global() );

    Log::debug() << "MatchingMeshPartitionerSphericalPolygon::partition" << std::endl;

    // FIXME: THIS IS A HACK! the coordinates include North/South Pole (first/last
    // partitions only)
    bool includesNorthPole = ( mpi_rank == 0 );
    bool includesSouthPole = ( mpi_rank == mpi_size - 1 );

    const util::SphericalPolygon poly( prePartitionedMesh_.polygon( 0 ), prePartitionedMesh_.nodes().lonlat() );
    const double maxlat = poly.coordinatesMax().lat();
    const double minlat = poly.coordinatesMin().lat();
    auto at_the_pole    = [&]( const PointLonLat& P ) {
        return ( includesNorthPole && P.lat() >= maxlat ) || ( includesSouthPole && P.lat() < minlat );
    };

    {
        eckit::ProgressTimer timer( "Partitioning", grid.size(), "point", double( 10 ), atlas::Log::trace() );
        size_t i = 0;

        for ( const PointXY Pxy : grid.xy() ) {
            ++timer;
            const PointLonLat P = grid.projection().lonlat( Pxy );
            partitioning[i++]   = at_the_pole( P ) || poly.contains( P ) ? mpi_rank : -1;
        }
    }

    // Synchronize partitioning, do a sanity check
    comm.allReduceInPlace( partitioning, grid.size(), eckit::mpi::Operation::MAX );
    const int min = *std::min_element( partitioning, partitioning + grid.size() );
    if ( min < 0 ) {
        throw_Exception(
            "Could not find partition for target node (source "
            "mesh does not contain all target grid points)",
            Here() );
    }
}

}  // namespace partitioner
}  // namespace detail
}  // namespace grid
}  // namespace atlas
