/+
    This file is part of Reloaded Vibes.
    Copyright (c) 2019  0xEAB

    Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE_1_0.txt or copy at
             https://www.boost.org/LICENSE_1_0.txt)
 +/
module reloadedvibes.utils;

import std.algorithm : canFind, count;
import std.ascii : isDigit;
import std.conv : to;
import std.string : indexOf, isNumeric;

@safe pure:

struct Socket
{
	string address;
	ushort port;

	string toString() const @safe pure nothrow
	{
		// dfmt off
		return (this.address.isIPv6)
			? '[' ~ this.address ~ "]:" ~ this.port.to!string
			: this.address ~ ':' ~ this.port.to!string;
		// dfmt on
	}
}

/++
	Determines whether the passed string is an IPv6 address (and not an IPv4 one).
	Use this function to differentiate between IPv4 and IPv6 addresses.

	Limitation:
		This functions does only very basic and cheap testing.
		It does not validate the IPv6 address at all.
		Never pass any sockets to it - IPv4 ones will get detected as IPv6 addresses.
		Do not use it for anything else than differentiating IPv4/IPv6 addresses.

	Returns:
		true if the passed string could looks like an IPv6 address
 +/
bool isIPv6(string address) nothrow @nogc
{
	foreach (c; address)
	{
		if (c == ':')
		{
			return true;
		}
	}

	return false;
}

unittest
{
	assert("127.0.0.1".isIPv6 == false);
	assert("::1".isIPv6);
}

/++
	Tries to parse a socket string

	Supports both IPv4 and IPv6.
	Does limited validating.

	Returns:
		true if parsing was successfull,
		false indicates bad/invalid input
 +/
bool tryParseSocket(string s, out Socket socket)
{
	socket = Socket();

	if ((s is null) && (s.length == 0)) // validate
	{
		return false;
	}

	immutable possiblePortSep = s.indexOf(':');

	size_t isIPv6 = 0;

	if (s[0] == '[')
	{
		// IPv6

		immutable ipv6end = s.indexOf(']');
		if (ipv6end < 3)
		{
			return false;
		}

		socket.address = s[1 .. ipv6end];

		isIPv6 = s.indexOf(':', ipv6end);
	}
	else if (possiblePortSep > -1)
	{
		// IPv4
		socket.address = s[0 .. possiblePortSep];

		if (socket.address.count!(c => c == '.') != 3) // validate
		{
			return false;
		}
	}
	else
	{
		return false;
	}

	immutable portSep = (isIPv6) ? isIPv6 : possiblePortSep;

	if (portSep == 0) // validate
	{
		return false;
	}

	string port = s[(portSep + 1) .. $];

	if (port.canFind!(d => !d.isDigit)() || (port.length > 5) || (port[0] == '-')) // validate
	{
		return false;
	}

	immutable portInt = port.to!int;
	if (portInt > ushort.max) // validate
	{
		return false;
	}

	socket.port = cast(ushort)(portInt);
	return true;
}

unittest
{
	import std.conv : to;
	import std.typecons : tuple;

	auto sockets = [
		// dfmt off
		tuple("127.0.0.1:3001", true, Socket("127.0.0.1", 3001)),
		tuple("1.2.3.4:56", true, Socket("1.2.3.4", 56)),
		tuple("127.0.0.1:123456", false, Socket()),
		tuple("[::1]:80", true, Socket("::1", 80)),
		tuple("[1]]:3001", false, Socket()),
		tuple("10.0.0.1", false, Socket()),
		tuple("[2001:db8:1234:0000:0000:0000:0000:0000]:443", true, Socket("2001:db8:1234:0000:0000:0000:0000:0000", 443)),
		tuple("[2001:db8::1]", false, Socket()),
		tuple(":1", false, Socket()),
		tuple("::11", false, Socket()),
		tuple("12.1:10", false, Socket()),
		tuple("1.2.3.4:-56", false, Socket()),
		// dfmt on
	];

	foreach (idx, s; sockets)
	{
		Socket x;

		immutable r = tryParseSocket(s[0], x);

		assert(r == s[1], "Unexpected parser result: [" ~ idx.to!string ~ "] " ~ s[0] ~ " -> " ~ r.to!string);

		if (r)
		{
			assert(x == s[2], "Wrongly parsed: [" ~ idx.to!string ~ "] " ~ s[0]);
		}
	}
}
