/*
 * (C) Copyright 1996-2012 ECMWF.
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 * In applying this licence, ECMWF does not waive the privileges and immunities 
 * granted to it by virtue of its status as an intergovernmental organisation nor
 * does it submit to any jurisdiction.
 */

/// @author Baudouin Raoult - ECMWF Dec 03
/// @author Simon Smart
/// ECMWF Dec 03

#ifndef eckit_sql_ParameterExpression_H
#define eckit_sql_ParameterExpression_H

#include "eckit/sql/expression/SQLExpression.h"

namespace eckit {
namespace sql {
namespace expression {

//----------------------------------------------------------------------------------------------------------------------

class ParameterExpression : public SQLExpression {
public:
	ParameterExpression(int);
	ParameterExpression(const ParameterExpression&);
	~ParameterExpression(); 

    std::shared_ptr<SQLExpression> clone() const override;
    std::shared_ptr<SQLExpression> reshift(int minColumnShift) const override { return clone(); }

private:
// No copy allowed
	ParameterExpression& operator=(const ParameterExpression&);

// -- Members
	// None
	double value_;
	int    which_;

	virtual void print(std::ostream& s) const override;
	virtual void prepare(SQLSelect& sql) override;
	virtual void cleanup(SQLSelect& sql) override;

	virtual double eval(bool& missing) const override;
	virtual const type::SQLType* type() const override;
	virtual bool isConstant() const override;
};

//----------------------------------------------------------------------------------------------------------------------

} // namespace expression 
} // namespace sql 
} // namespace eckit

#endif
