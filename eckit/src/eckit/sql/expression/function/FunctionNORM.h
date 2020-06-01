/*
 * (C) Copyright 1996-2012 ECMWF.
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 * In applying this licence, ECMWF does not waive the privileges and immunities 
 * granted to it by virtue of its status as an intergovernmental organisation nor
 * does it submit to any jurisdiction.
 */

// File FunctionNORM.h
// ECMWF July 2010

#ifndef FunctionNORM_H
#define FunctionNORM_H

#include "eckit/sql/expression/function/FunctionExpression.h"

namespace eckit {
namespace sql {
namespace expression {
namespace function {

class FunctionNORM : public FunctionExpression {
public:
	FunctionNORM(const std::string&,const expression::Expressions&);
	FunctionNORM(const FunctionNORM&);
	~FunctionNORM();

	std::shared_ptr<SQLExpression> clone() const;

    static int arity() { return 2; }

private:
// No copy allowed
	FunctionNORM& operator=(const FunctionNORM&);

	double value_;

// -- Overridden methods
	virtual const eckit::sql::type::SQLType* type() const;
	virtual void prepare(SQLSelect&);
	virtual void cleanup(SQLSelect&);
	virtual void partialResult();
	virtual double eval(bool& missing) const;

	bool isAggregate() const { return true; }
	bool resultNULL_;
// -- Friends
	//friend std::ostream& operator<<(std::ostream& s,const FunctionNORM& p)
	//	{ p.print(s); return s; }
};

} // namespace function
} // namespace expression 
} // namespace sql
} // namespace eckit

#endif
