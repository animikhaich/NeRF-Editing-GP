#pragma once
/*===========================================================================*\
 *                                                                           *
 *                            OpenVolumeMesh                                 *
 *        Copyright (C) 2011 by Computer Graphics Group, RWTH Aachen         *
 *                        www.openvolumemesh.org                             *
 *                                                                           *
 *---------------------------------------------------------------------------*
 *  This file is part of OpenVolumeMesh.                                     *
 *                                                                           *
 *  OpenVolumeMesh is free software: you can redistribute it and/or modify   *
 *  it under the terms of the GNU Lesser General Public License as           *
 *  published by the Free Software Foundation, either version 3 of           *
 *  the License, or (at your option) any later version with the              *
 *  following exceptions:                                                    *
 *                                                                           *
 *  If other files instantiate templates or use macros                       *
 *  or inline functions from this file, or you compile this file and         *
 *  link it with other files to produce an executable, this file does        *
 *  not by itself cause the resulting executable to be covered by the        *
 *  GNU Lesser General Public License. This exception does not however       *
 *  invalidate any other reasons why the executable file might be            *
 *  covered by the GNU Lesser General Public License.                        *
 *                                                                           *
 *  OpenVolumeMesh is distributed in the hope that it will be useful,        *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            *
 *  GNU Lesser General Public License for more details.                      *
 *                                                                           *
 *  You should have received a copy of the GNU LesserGeneral Public          *
 *  License along with OpenVolumeMesh.  If not,                              *
 *  see <http://www.gnu.org/licenses/>.                                      *
 *                                                                           *
\*===========================================================================*/

#include <iosfwd>
#include <OpenVolumeMesh/Config/Export.hh>

namespace OpenVolumeMesh {

/** \class OpenVolumeMeshStatus
 *
 * \brief Stores statuses like selected, tagged, deleted, hidden.
 */

class OVM_EXPORT OpenVolumeMeshStatus {
public:

    OpenVolumeMeshStatus() = default;

    bool selected() const { return selected_; }

    bool tagged() const { return tagged_; }

    bool deleted() const { return deleted_; }

    bool hidden() const { return hidden_;}

    void set_selected(bool _selected) { selected_ = _selected; }

    void set_tagged(bool _tagged) { tagged_ = _tagged; }

    void set_deleted(bool _deleted) { deleted_ = _deleted; }

    void set_hidden(bool _hidden) {hidden_ = _hidden;}

private:

    bool selected_ = false;

    bool tagged_ = false;

    bool deleted_ = false;

    bool hidden_ = false;
};

std::ostream& operator<<(std::ostream& _ostr, const OpenVolumeMeshStatus& _status);

std::istream& operator>>(std::istream& _istr, OpenVolumeMeshStatus& _status);

} // Namespace OpenVolumeMesh

