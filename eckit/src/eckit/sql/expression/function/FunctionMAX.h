/*
 * (C) Copyright 1996-2012 ECMWF.
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 * In applying this licence, ECMWF does not waive the privileges and immunities 
 * granted to it by virtue of its status as an intergovernmental organisation nor
 * does it submit to any jurisdiction.
 */

// File FunctionMAX.h
// Baudouin Raoult - ECMWF Dec 03

#ifndef FunctionMAX_H
#define FunctionMAX_H

#include "eckit/sql/expression/function/FunctionExpression.h"

namespace eckit {
namespace sql {
namespace expression {
namespace function {

class FunctionMAX : public FunctionExpression {
public:
	FunctionMAX(const std::string&,const expression::Expressions&);
	FunctionMAX(const FunctionMAX&);
	~FunctionMAX(); 

	std::shared_ptr<SQLExpression> clone() const;

    static int arity() { return 1; }

private:
// No copy allowed
	FunctionMAX& operator=(const FunctionMAX&);

	double value_;

// -- Overridden methods
	virtual const eckit::sql::type::SQLType* type() const;
	virtual void prepare(SQLSelect&);
	virtual void cleanup(SQLSelect&);
	virtual void partialResult();
	virtual double eval(bool& missing) const;
	bool isAggregate() const { return true; }

	virtual void output(SQLOutput&) const;

// -- Friends
	//friend std::ostream& operator<<(std::ostream& s,const FunctionMAX& p)
	//	{ p.print(s); return s; }
};

} // namespace function
} // namespace expression 
} // namespace sql
} // namespace eckit

#endif
