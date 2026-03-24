import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { HomePage } from './HomePage'

const mocks = vi.hoisted(() => {
  return {
    signOut: vi.fn(),
    createBip21PaymentUri: vi.fn(),
    parseBip21Input: vi.fn(),
    toUnifiedBip21Error: vi.fn(),
  }
})

vi.mock('../auth/useAuth', () => {
  return {
    useAuth: () => ({
      signOut: mocks.signOut,
    }),
  }
})

vi.mock('../api/walletApi', async () => {
  const actual = await vi.importActual<typeof import('../api/walletApi')>('../api/walletApi')
  return {
    ...actual,
    walletApi: {
      ...actual.walletApi,
      getHealth: vi.fn(),
    },
  }
})

vi.mock('../lib/bip21', () => {
  return {
    createBip21PaymentUri: mocks.createBip21PaymentUri,
    parseBip21Input: mocks.parseBip21Input,
    toUnifiedBip21Error: mocks.toUnifiedBip21Error,
  }
})

describe('HomePage', () => {
  beforeEach(() => {
    mocks.signOut.mockReset()
    mocks.createBip21PaymentUri.mockReset()
    mocks.parseBip21Input.mockReset()
    mocks.toUnifiedBip21Error.mockReset()
    mocks.toUnifiedBip21Error.mockReturnValue('BIP-21 输入有误：URI 格式无效')
  })

  it('可生成支付 URI 并展示到输入与结果区域', () => {
    mocks.createBip21PaymentUri.mockReturnValue('bitcoin:soulon1xyz?amount=2&memo=tip')

    render(
      <MemoryRouter>
        <HomePage />
      </MemoryRouter>,
    )

    fireEvent.change(screen.getByLabelText('收款地址'), {
      target: { value: 'soulon1xyz' },
    })
    fireEvent.change(screen.getByLabelText('金额（可选）'), {
      target: { value: '2' },
    })
    fireEvent.change(screen.getByLabelText('备注（可选）'), {
      target: { value: 'tip' },
    })
    fireEvent.click(screen.getByRole('button', { name: '生成支付 URI' }))

    expect(mocks.createBip21PaymentUri).toHaveBeenCalledWith({
      address: 'soulon1xyz',
      amount: '2',
      memo: 'tip',
    })
    expect(screen.getByLabelText('URI 粘贴/扫码结果')).toHaveValue('bitcoin:soulon1xyz?amount=2&memo=tip')
    expect(screen.getByLabelText('已生成 URI')).toHaveValue('bitcoin:soulon1xyz?amount=2&memo=tip')
  })

  it('可解析 URI 并回填到手动输入表单', () => {
    mocks.parseBip21Input.mockReturnValue({
      address: 'soulon1parsed',
      amount: '3.5',
      memo: 'coffee',
    })

    render(
      <MemoryRouter>
        <HomePage />
      </MemoryRouter>,
    )

    fireEvent.change(screen.getByLabelText('URI 粘贴/扫码结果'), {
      target: { value: 'bitcoin:soulon1parsed?amount=3.5&memo=coffee' },
    })
    fireEvent.click(screen.getByRole('button', { name: '解析并回填表单' }))

    expect(mocks.parseBip21Input).toHaveBeenCalledWith('bitcoin:soulon1parsed?amount=3.5&memo=coffee')
    expect(screen.getByLabelText('收款地址')).toHaveValue('soulon1parsed')
    expect(screen.getByLabelText('金额（可选）')).toHaveValue('3.5')
    expect(screen.getByLabelText('备注（可选）')).toHaveValue('coffee')
  })

  it('解析失败时展示统一错误且不覆盖现有手动输入', () => {
    mocks.parseBip21Input.mockImplementation(() => {
      throw new Error('invalid')
    })

    render(
      <MemoryRouter>
        <HomePage />
      </MemoryRouter>,
    )

    fireEvent.change(screen.getByLabelText('收款地址'), {
      target: { value: 'soulon1keep' },
    })
    fireEvent.change(screen.getByLabelText('金额（可选）'), {
      target: { value: '9.9' },
    })
    fireEvent.change(screen.getByLabelText('备注（可选）'), {
      target: { value: 'old memo' },
    })
    fireEvent.change(screen.getByLabelText('URI 粘贴/扫码结果'), {
      target: { value: 'not-a-bip21' },
    })
    fireEvent.click(screen.getByRole('button', { name: '解析并回填表单' }))

    expect(mocks.toUnifiedBip21Error).toHaveBeenCalled()
    expect(screen.getByText('BIP-21 输入有误：URI 格式无效')).toBeInTheDocument()
    expect(screen.getByLabelText('收款地址')).toHaveValue('soulon1keep')
    expect(screen.getByLabelText('金额（可选）')).toHaveValue('9.9')
    expect(screen.getByLabelText('备注（可选）')).toHaveValue('old memo')
  })
})
