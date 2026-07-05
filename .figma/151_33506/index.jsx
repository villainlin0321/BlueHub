import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.frame4}>
      <p className={styles.text}>现在退出，内容将不会保存</p>
      <div className={styles.frame3}>
        <div className={styles.frame}>
          <p className={styles.text2}>取消</p>
        </div>
        <div className={styles.frame2}>
          <p className={styles.text3}>确定</p>
        </div>
      </div>
    </div>
  );
}

export default Component;
