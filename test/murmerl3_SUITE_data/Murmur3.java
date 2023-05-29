import java.nio.charset.StandardCharsets;
import java.util.function.ToIntFunction;

public class Murmur3 {

  public static void main(String[] args) {
    if (args.length != 1) {
      System.err.println("Please provide a string argument to hash");
      System.exit(1);
    }
    System.out.println(Integer.toUnsignedString(new Murmur3Hash().applyAsInt(args[0])));
  }

  static class Murmur3Hash implements ToIntFunction<String> {

    private static final int C1_32 = 0xcc9e2d51;
    private static final int C2_32 = 0x1b873593;
    private static final int R1_32 = 15;
    private static final int R2_32 = 13;
    private static final int M_32 = 5;
    private static final int N_32 = 0xe6546b64;

    private static int getLittleEndianInt(final byte[] data, final int index) {
      return ((data[index] & 0xff))
          | ((data[index + 1] & 0xff) << 8)
          | ((data[index + 2] & 0xff) << 16)
          | ((data[index + 3] & 0xff) << 24);
    }

    private static int mix32(int k, int hash) {
      k *= C1_32;
      k = Integer.rotateLeft(k, R1_32);
      k *= C2_32;
      hash ^= k;
      return Integer.rotateLeft(hash, R2_32) * M_32 + N_32;
    }

    private static int fmix32(int hash) {
      hash ^= (hash >>> 16);
      hash *= 0x85ebca6b;
      hash ^= (hash >>> 13);
      hash *= 0xc2b2ae35;
      hash ^= (hash >>> 16);
      return hash;
    }

    @Override
    public int applyAsInt(String value) {
      byte[] data = value.getBytes(StandardCharsets.UTF_8);
      final int offset = 0;
      final int length = data.length;
      final int seed = 104729;
      int hash = seed;
      final int nblocks = length >> 2;

      // body
      for (int i = 0; i < nblocks; i++) {
        final int index = offset + (i << 2);
        final int k = getLittleEndianInt(data, index);
        hash = mix32(k, hash);
      }

      // tail
      final int index = offset + (nblocks << 2);
      int k1 = 0;
      switch (offset + length - index) {
        case 3:
          k1 ^= (data[index + 2] & 0xff) << 16;
        case 2:
          k1 ^= (data[index + 1] & 0xff) << 8;
        case 1:
          k1 ^= (data[index] & 0xff);

          // mix functions
          k1 *= C1_32;
          k1 = Integer.rotateLeft(k1, R1_32);
          k1 *= C2_32;
          hash ^= k1;
      }

      hash ^= length;
      return fmix32(hash);
    }
  }
}