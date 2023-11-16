//@ts-nocheck
import React, { useEffect, useRef, useState } from 'react';
import Image from 'next/legacy/image';
import { useRouter } from 'next/router';
import { Modal, Form, Input, Button, DatePicker, message, Select, Typography } from 'antd';
import type { FormInstance } from 'antd/es/form';
import { ethers } from 'ethers';
import { DEFAULT_ORG, DEFAULT_ORG_OWNER, ORG_MINTER } from '../config/index';
import mintABI from '../abis/mint.json';

const { Paragraph, Text } = Typography;

import dayjs from 'dayjs';
type FieldType = {
  title?: string;
  to?: string;
  date?: string;
  desc?: string;
  tokenType?: number;
};
const { TextArea } = Input;
const ProfilePage: React.FC = () => {
  const router = useRouter(); // Initialize the router
  const [mintList, setMintList] = useState<any>([]);

  const mintAddress = ORG_MINTER;
  const defaultAddress = DEFAULT_ORG_OWNER;

  const [isSubmitting, setisSubmitting] = useState<boolean>(false);

  const getMintNFTList = async () => {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const contract = new ethers.Contract(mintAddress, mintABI, provider);

    try {
      const orgTokenHolders = await contract.getOrgTokenHolders(DEFAULT_ORG);

      if (!orgTokenHolders.length) {
        setMintList([]);
        return;
      }

      const tasks = orgTokenHolders.map((address: string) => contract.getTokenInfo(DEFAULT_ORG, address));
      const list = await Promise.all(tasks);

      const formatList = list.map((item) => ({
        orgId: item.orgId.toNumber(),
        to: item.to,
        tokenType: item.tokenType, // 0，1，2
        date: item.date.toNumber(),
        title: item.title,
        desc: item.desc,
      }));

      setMintList(formatList);
    } catch (error: any) {
      console.error(error);
      alert('get mint list failed, ' + error.toString());
    }
  };
  const formRef = useRef<FormInstance>(null);

  const [isIssueCredentialsDialogShow, setisIssueCredentialsDialogShow] = useState<boolean>(false);

  const openIssueCredentials = () => {
    setisIssueCredentialsDialogShow(true);
  };

  const closeIssueCredentials = () => {
    setisIssueCredentialsDialogShow(true);
    formRef?.current?.resetFields();

    setisIssueCredentialsDialogShow(false);
  };

  const submitCredentials = async () => {
    let flag = true;

    try {
      await formRef?.current?.validateFields();
    } catch (error) {
      flag = false;
    }

    if (!flag) return;

    if (isSubmitting) return;

    try {
      setisSubmitting(true);
      const formdata = formRef?.current?.getFieldsValue(true) || {};

      const { title, to, date, desc, tokenType } = formdata;

      const timestamp = dayjs(date).unix();

      await mintNFT(to, title, desc, tokenType, timestamp);

      await getMintNFTList();

      formRef?.current?.resetFields();

      setisIssueCredentialsDialogShow(false);
    } catch (error: any) {
      console.error(error);
      message.error('mint failed:', error.toString());
    } finally {
      setisSubmitting(false);
    }
  };

  const mintNFT = async (to: string, title: string, desc: string, tokenType: number, timestamp: number) => {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(mintAddress, mintABI, signer);

    const tx = await contract.mint({
      orgId: DEFAULT_ORG,
      to,
      tokenType, // 0，1，2
      date: timestamp,
      title,
      desc,
    });

    console.log(tx.hash);

    await tx.wait();

    message.success('mint success, tx hash ' + tx.hash);
  };

  const init = () => {
    let provider = new ethers.providers.Web3Provider(window.ethereum);
    // if (provider?.provider?.selectedAddress?.toLowerCase() !== defaultAddress?.toLowerCase()) {
    //   return router.replace('/');
    // }
    setTimeout(() => {
      provider = new ethers.providers.Web3Provider(window.ethereum);
      if (provider?.provider?.selectedAddress?.toLowerCase() !== defaultAddress?.toLowerCase()) {
        return router.replace('/');
      }
    }, 500)

    window.ethereum.on('accountsChanged', function () {
      if (provider?.provider?.selectedAddress?.toLowerCase() !== defaultAddress?.toLowerCase()) {
        router.replace('/');
      }
    });

    getMintNFTList();
  };

  useEffect(() => {
    init();
  }, []);

  return (
    <div className='bg-black text-white min-h-screen '>
      <main className='container mx-auto p-4'>
        <section className='text-center mb-10'>
          <div className='inline-block relative'>
            <img src='/availability.jpg' alt='' className='' />
          </div>
        </section>

        <section className='text-center mb-10'>
          {mintList && mintList.length ? (
            <div className='flex flex-wrap '>
              {mintList.map((item: any, index: number) => {
                return (
                  <div
                    className='text-left text-xs w-[400px] bg-slate-700 mr-2 mb-2 p-4 rounded-sm'
                    key={`${item.orgId}_${item.date}_${index}`}>
                    <div className='mb-1'>
                      <Text className='text-lg text-violet-600' ellipsis>
                        {item.title}
                      </Text>
                    </div>
                    <div className='mb-1 '>Date Completed: {dayjs.unix(item.date).format('YYYY-MM-DD')}</div>
                    <div className='mb-1 flex items-baseline'>
                      <div>Desc: </div>
                      <Paragraph
                        className='text-white ml-1 text-[12px] !mb-0'
                        ellipsis={{ rows: 3, expandable: false }}>
                        {item.desc}
                      </Paragraph>
                    </div>
                    <div className=''>To {item.to}</div>
                  </div>
                );
              })}
            </div>
          ) : (
            <>
              <div className='text-4xl'>You have not issued Credentials yet.</div>
              <div className='mt-2 text-md'>Go to your Dashboard and issuing credentials to your community!</div>
            </>
          )}

          <img
            className='cursor-pointer inline-block mt-16 w-72 h-12'
            src='/createCredentialsBtn.jpg'
            alt=''
            onClick={openIssueCredentials}
          />
        </section>

        <footer className='flex flex-col items-center justify-between py-10'>
          <div className='text-center mb-6'>
            <p>SuperLancersAI</p>
            <p>A freelancer network built on trust and verifiable credentials</p>
          </div>
          <div className='mb-6'>
            <Image src='/socials.png' alt='Social Links' width={120} height={40} />
          </div>
          <p>&copy; 2023 CredLancers, All rights reserved.</p>
        </footer>
      </main>

      <Modal title='Issue Credentials' width={800} open={isIssueCredentialsDialogShow} closeIcon={null} footer={null}>
        <Form
          disabled={isSubmitting}
          labelCol={{ span: 8 }}
          wrapperCol={{ span: 16 }}
          style={{ maxWidth: 600 }}
          ref={formRef}
          initialValues={{
            tokenType: 0,
            title: '',
            to: '',
            date: '',
            desc: '',
          }}
          autoComplete='off'>
          <Form.Item<FieldType> label='Type' name='tokenType'>
            <Select>
              <Select.Option value={0}>Certificate</Select.Option>
              <Select.Option value={1}>Membership</Select.Option>
              <Select.Option value={2}>Project</Select.Option>
            </Select>
          </Form.Item>
          <Form.Item<FieldType> label='Title' name='title' rules={[{ required: true, message: 'Please input title' }]}>
            <Input />
          </Form.Item>

          <Form.Item<FieldType>
            label='Desc'
            name='desc'
            rules={[{ required: true, message: 'Please input description  ' }]}>
            <TextArea rows={4} />
          </Form.Item>

          <Form.Item<FieldType>
            label='To Whom'
            name='to'
            rules={[{ required: true, message: 'Please input to whom address' }]}>
            <Input />
          </Form.Item>

          <Form.Item<FieldType>
            label='date'
            name='date'
            rules={[{ type: 'object' as const, required: true, message: 'Please select time!' }]}>
            <DatePicker />
          </Form.Item>

          <Form.Item wrapperCol={{ offset: 8, span: 16 }}>
            <Button loading={isSubmitting} onClick={submitCredentials}>
              Submit
            </Button>
            <Button disabled={isSubmitting} className='ml-2' onClick={closeIssueCredentials}>
              Cancel
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default ProfilePage;
