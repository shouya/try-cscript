require_relative 'common.rb'

simple_test [2, 4, 7, 3] do
    '''
/* basic if */
if (1) {
   EMIT 2;
   EMIT 4;
}
else {
   EMIT 3;
}

if (0) {
   EMIT 1;
}

else
{
   EMIT 7;
}

if (1)
  EMIT 1+2;

    '''
end

