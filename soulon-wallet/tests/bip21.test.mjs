import test from "node:test";
import assert from "node:assert/strict";
import {
  BIP21_ERROR_CODES,
  SoulonWalletError,
  generateBip21Uri,
  parseBip21Uri
} from "../dist/index.js";

test("generateBip21Uri: 生成包含 amount 与 memo 的 URI", () => {
  const uri = generateBip21Uri({
    scheme: "bitcoin",
    address: "soulon1abcde12345",
    amount: "1.25",
    memo: "for coffee"
  });
  assert.equal(uri, "bitcoin:soulon1abcde12345?amount=1.25&memo=for+coffee");
});

test("generateBip21Uri: 使用默认 scheme 并忽略空 memo", () => {
  const uri = generateBip21Uri({
    address: "soulon1abcde12345",
    memo: "   "
  });
  assert.equal(uri, "bitcoin:soulon1abcde12345");
});

test("generateBip21Uri: 地址为空时报错", () => {
  assert.throws(
    () => {
      generateBip21Uri({
        address: "   "
      });
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, BIP21_ERROR_CODES.INVALID_ADDRESS);
      return true;
    }
  );
});

test("generateBip21Uri: amount 非法时报错", () => {
  assert.throws(
    () => {
      generateBip21Uri({
        address: "soulon1abcde12345",
        amount: "-1"
      });
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, BIP21_ERROR_CODES.INVALID_AMOUNT);
      return true;
    }
  );
});

test("parseBip21Uri: 可解析 amount memo 与 message 兼容字段", () => {
  const parsedWithMemo = parseBip21Uri("bitcoin:soulon1abcde12345?amount=2.5&memo=tip");
  assert.deepEqual(parsedWithMemo, {
    scheme: "bitcoin",
    address: "soulon1abcde12345",
    amount: "2.5",
    memo: "tip"
  });
  const parsedWithMessage = parseBip21Uri("bitcoin:soulon1abcde12345?message=thanks");
  assert.deepEqual(parsedWithMessage, {
    scheme: "bitcoin",
    address: "soulon1abcde12345",
    memo: "thanks"
  });
});

test("parseBip21Uri: URI 缺少 scheme 分隔符时报错", () => {
  assert.throws(
    () => {
      parseBip21Uri("soulon1abcde12345?amount=1");
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, BIP21_ERROR_CODES.INVALID_URI);
      return true;
    }
  );
});

test("parseBip21Uri: amount 非法时报错", () => {
  assert.throws(
    () => {
      parseBip21Uri("bitcoin:soulon1abcde12345?amount=0");
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, BIP21_ERROR_CODES.INVALID_AMOUNT);
      return true;
    }
  );
});
