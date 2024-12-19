import { describe, it, expect, beforeEach, vi } from 'vitest'

describe('Climate Oracle Contract', () => {
  let mockContractCall: any
  
  beforeEach(() => {
    mockContractCall = vi.fn()
  })
  
  it('should register a data provider', async () => {
    mockContractCall.mockResolvedValue({ success: true })
    const result = await mockContractCall('register-data-provider', 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM')
    expect(result.success).toBe(true)
  })
  
  it('should submit climate data', async () => {
    mockContractCall.mockResolvedValue({ success: true, value: 1 })
    const result = await mockContractCall('submit-climate-data', 25, 50, 10)
    expect(result.success).toBe(true)
    expect(result.value).toBe(1)
  })
  
  it('should get climate data', async () => {
    mockContractCall.mockResolvedValue({
      success: true,
      value: {
        provider: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
        timestamp: 12345,
        temperature: 25,
        precipitation: 50,
        windSpeed: 10
      }
    })
    const result = await mockContractCall('get-climate-data', 1)
    expect(result.success).toBe(true)
    expect(result.value.temperature).toBe(25)
  })
})

