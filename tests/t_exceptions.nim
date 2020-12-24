import ../wasmrt

echo "exceptions..."

proc bar() =
  raise newException(Exception, "Exception msg")

proc foo() =
  try:
    echo "hi"
    bar()
  except Exception as e:
    echo "Exception caught: ", e.msg
  finally:
    echo "finally called"

foo()
