// Copyright (c) 2015-2016 David Turnbull
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and/or associated documentation files (the
// "Materials"), to deal in the Materials without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Materials, and to
// permit persons to whom the Materials are furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Materials.
//
// THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.


#if !os(Linux)
    import simd
#endif


public struct Vector2i<T:IntegerScalarType> : IntegerVectorType {

    public typealias Element = T
    public typealias FloatVector = Vector2<Float>
    public typealias DoubleVector = Vector2<Double>
    public typealias Int32Vector = Vector2i<Int32>
    public typealias UInt32Vector = Vector2i<UInt32>
    public typealias BooleanVector = Vector2b

    public var x:T, y:T

    public var r:T { get {return x} set {x = newValue} }
    public var g:T { get {return y} set {y = newValue} }

    public var s:T { get {return x} set {x = newValue} }
    public var t:T { get {return y} set {y = newValue} }

    public var startIndex: Int { return 0 }
    public var endIndex: Int { return 2 }

    public subscript(i: Int) -> T {
        get {

            switch(i) {
            case 0: return x
            case 1: return y
            default: preconditionFailure("Vector index out of range")
            }
        }
        set {
            switch(i) {
            case 0: x = newValue
            case 1: y = newValue
            default: preconditionFailure("Vector index out of range")
            }
        }
    }

    public var debugDescription: String {
        return String(self.dynamicType) + "(\(x), \(y))"
    }

    public var hashValue: Int {
        return SwiftGLmath.hash(x.hashValue, y.hashValue)
    }

    public init () {
        self.x = T(0)
        self.y = T(0)
    }

    public init (_ v:T) {
        self.x = v
        self.y = v
    }

    public init (_ x:T, _ y:T) {
        self.x = x
        self.y = y
    }

    public init (x:T, y:T) {
        self.x = x
        self.y = y
    }

    public init (r:T, g:T) {
        self.x = r
        self.y = g
    }

    public init (s:T, t:T) {
        self.x = s
        self.y = t
    }

    public init (_ v:Vector2<Float>) {
        self.x = T(v.x)
        self.y = T(v.y)
    }

    public init (_ v:Vector2<Double>) {
        self.x = T(v.x)
        self.y = T(v.y)
    }

    public init (_ v:Vector2i<Int32>) {
        self.x = T(v.x)
        self.y = T(v.y)
    }

    public init (_ v:Vector2i<UInt32>) {
        self.x = T(v.x)
        self.y = T(v.y)
    }

    public init (_ v:Vector2i<T>) {
        self.x = v.x
        self.y = v.y
    }

    public init (_ v:Vector3i<T>) {
        self.x = v.x
        self.y = v.y
    }

    public init (_ v:Vector4i<T>) {
        self.x = v.x
        self.y = v.y
    }

    public init (_ s:T, _ v:Vector2i<T>, @noescape _ op:(_:T, _:T) -> T) {
        self.x = op(s, v.x)
        self.y = op(s, v.y)
    }

    public init (_ v:Vector2i<T>, _ s:T, @noescape _ op:(_:T, _:T) -> T) {
        self.x = op(v.x, s)
        self.y = op(v.y, s)
    }

    public init<T:VectorType where T.BooleanVector == BooleanVector>
        (_ v: T, @noescape _ op:(_:T.Element) -> Element) {
            self.x = op(v[0])
            self.y = op(v[1])
    }

    public init<T1:VectorType, T2:VectorType where
        T1.BooleanVector == BooleanVector, T2.BooleanVector == BooleanVector>
        (_ v1:T1, _ v2:T2, @noescape _ op:(_:T1.Element, _:T2.Element) -> Element) {
            self.x = op(v1[0], v2[0])
            self.y = op(v1[1], v2[1])
    }

    public init<T1:VectorType, T2:VectorType where
        T1.BooleanVector == BooleanVector, T2.BooleanVector == BooleanVector>
        (_ v1:T1, inout _ v2:T2, @noescape _ op:(_:T1.Element, inout _:T2.Element) -> Element) {
            self.x = op(v1[0], &v2[0])
            self.y = op(v1[1], &v2[1])
    }

    public init<T1:VectorType, T2:VectorType, T3:VectorType where
        T1.BooleanVector == BooleanVector, T2.BooleanVector == BooleanVector, T3.BooleanVector == BooleanVector>
        (_ v1:T1, _ v2:T2, _ v3:T3, @noescape _ op:(_:T1.Element, _:T2.Element, _:T3.Element) -> Element) {
            self.x = op(v1[0], v2[0], v3[0])
            self.y = op(v1[1], v2[1], v3[1])
    }

}


public func ==<T:IntegerScalarType>(v1: Vector2i<T>, v2: Vector2i<T>) -> Bool {
    return v1.x == v2.x && v1.y == v2.y
}


@warn_unused_result
public prefix func +<T:IntegerScalarType where T:SignedIntegerType>(v: Vector2i<T>) -> Vector2i<T> {
    return v
}

@warn_unused_result
public prefix func -<T:IntegerScalarType where T:SignedIntegerType>(v: Vector2i<T>) -> Vector2i<T> {
    #if !os(Linux)
        if T.self == Int32.self || T.self == UInt32.self {
            return unsafeBitCast(-unsafeBitCast(v, int2.self), Vector2i<T>.self)
        }
    #endif
    return Vector2i<T>(-v.x, -v.y)
}