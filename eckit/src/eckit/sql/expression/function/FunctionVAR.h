/*
 * (C) Copyright 1996-2012 ECMWF.
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 * In applying this licence, ECMWF does not waive the privileges and immunities 
 * granted to it by virtue of its status as an intergovernmental organisation nor
 * does it submit to any jurisdiction.
 */

// File FunctionVAR.h
// Baudouin Raoult - ECMWF Dec 03

#ifndef FunctionVAR_H
#define FunctionVAR_H

#include "eckit/sql/expression/function/FunctionExpression.h"

namespace eckit {
namespace sql {
namespace expression {
namespace function {

class FunctionVAR : public FunctionExpression {
public:
	FunctionVAR(const std::string&, const expression::Expressions&);
	FunctionVAR(const FunctionVAR&);
	~FunctionVAR();

// -- Overridden methods
	virtual const eckit::sql::type::SQLType* type() const;
	virtual void prepare(SQLSelect&);
	virtual void cleanup(SQLSelect&);
	virtual void partialResult();

	bool isAggregate() const { return true; }

	std::shared_ptr<SQLExpression> clone() const;

    static int arity() { return 1; }

protected:

// -- Overridden methods
	virtual double eval(bool& missing) const;

private:
// No copy allowed
	FunctionVAR& operator=(const FunctionVAR&);

	unsigned long long count_;
	double value_;
	double squares_;

// -- Friends
	//friend std::ostream& operator<<(std::ostream& s,const FunctionVAR& p)
	//	{ p.print(s); return s; }
};

} // namespace function
} // namespace expression 
} // namespace sql
} // namespace eckit 

#endif
